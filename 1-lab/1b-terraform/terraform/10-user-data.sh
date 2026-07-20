#!/bin/bash
dnf update -y
dnf install -y python3-pip
dnf install -y amazon-cloudwatch-agent
pip3 install flask pymysql boto3


# ==============================
# cloudwatch agent configuration
# ==============================

# creates cloudwatch agent config directory
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

# retrieves cloudwatch agent configuration from parameter store
aws ssm get-parameter \
--name cloudwatch_agent_parameter \
--query Parameter.Value \
--output text \
> /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json


mkdir -p /opt/rdsapp
cat >/opt/rdsapp/app.py <<'PY'
import json
import os
import boto3
import pymysql
import logging
from flask import Flask, request

logging.basicConfig(
    filename="/var/log/rdsapp.log",
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s"
)

logger = logging.getLogger(__name__)



REGION = os.environ.get("AWS_REGION", "us-east-1")
SECRET_ID = os.environ.get("SECRET_ID")

secrets = boto3.client("secretsmanager", region_name=REGION)
ssm = boto3.client("ssm", region_name=REGION)

def get_parameter(name):
    response = ssm.get_parameter(Name=name)
    return response["Parameter"]["Value"]

def get_db_creds():
    resp = secrets.get_secret_value(SecretId=SECRET_ID)
    s = json.loads(resp["SecretString"])

    s["host"] = get_parameter("db_endpoint_parameter")
    s["port"] = get_parameter("db_port_parameter")
    s["dbname"] = get_parameter("db_name_parameter")
    return s

def get_conn():
    c = get_db_creds()
    host = c["host"]
    user = c["username"]
    password = c["password"]
    port = int(c["port"])
    db = c["dbname"]

    try:
        return pymysql.connect(
            host=host,
            user=user,
            password=password,
            port=port,
            database=db,
            autocommit=True
        )
    except Exception:
        logger.exception("Database connection failed")
        raise

app = Flask(__name__)

@app.route("/")
def home():
    return """
    <h2>EC2 → RDS Notes App</h2>
    <p>POST /add?note=hello</p>
    <p>GET /list</p>
    """

@app.route("/init")
def init_db():
    c = get_db_creds()
    host = c["host"]
    user = c["username"]
    password = c["password"]
    port = int(c["port"])
    db = c["dbname"]

    # connect without specifying a DB first
    conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)
    cur = conn.cursor()
    cur.execute(f"CREATE DATABASE IF NOT EXISTS `{db}`;")
    cur.execute(f"USE `{db}`;")

    cur.execute("""
        CREATE TABLE IF NOT EXISTS notes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            note VARCHAR(255) NOT NULL
        );
    """)
    cur.close()
    conn.close()
    return f"Initialized {db} + notes table."

@app.route("/add", methods=["POST", "GET"])
def add_note():
    note = request.args.get("note", "").strip()
    if not note:
        return "Missing note param. Try: /add?note=hello", 400
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))
    cur.close()
    conn.close()
    return f"Inserted note: {note}"

@app.route("/list")
def list_notes():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    out = "<h3>Notes</h3><ul>"
    for r in rows:
        out += f"<li>{r[0]}: {r[1]}</li>"
    out += "</ul>"
    return out

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
PY

cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
[Unit]
Description=EC2 to RDS Notes App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
Environment=SECRET_ID=${secret_id}
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
-s

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp

