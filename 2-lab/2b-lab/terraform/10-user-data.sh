#!/bin/bash
dnf update -y
dnf install -y python3-pip
dnf install -y amazon-cloudwatch-agent
systemctl stop amazon-cloudwatch-agent || true
pip3 install flask pymysql boto3


# ==============================
# cloudwatch agent configuration
# ==============================

# creates cloudwatch agent config directory
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

# retrieves cloudwatch agent configuration from parameter store
until aws ssm get-parameter \
--name cloudwatch_agent_parameter \
--query Parameter.Value \
--output text \
> /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
do
    echo "Waiting for SSM parameter access..."
    sleep 10
done


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


secrets = boto3.client(
    "secretsmanager",
    region_name=REGION
)

ssm = boto3.client(
    "ssm",
    region_name=REGION
)


def get_parameter(name):
    response = ssm.get_parameter(
        Name=name
    )

    return response["Parameter"]["Value"]



def get_db_creds():

    response = secrets.get_secret_value(
        SecretId=SECRET_ID
    )

    secret = json.loads(
        response["SecretString"]
    )

    secret["host"] = get_parameter(
        "db_endpoint_parameter"
    )

    secret["port"] = get_parameter(
        "db_port_parameter"
    )

    secret["dbname"] = get_parameter(
        "db_name_parameter"
    )

    return secret



def get_conn():

    try:

        creds = get_db_creds()

        return pymysql.connect(
            host=creds["host"],
            user=creds["username"],
            password=creds["password"],
            port=int(creds["port"]),
            database=creds["dbname"],
            autocommit=True
        )


    except pymysql.err.OperationalError as e:

        error = str(e)


        if "Access denied" in error:

            logger.exception(
                "DB_AUTH_FAILURE: Database authentication failed"
            )


        elif "timed out" in error:

            logger.exception(
                "DB_TIMEOUT_FAILURE: Database connection timed out"
            )


        elif "Can't connect" in error:

            logger.exception(
                "DB_CONNECTION_FAILURE: Database network connection failed"
            )


        else:

            logger.exception(
                "DB_UNKNOWN_FAILURE: Unknown database failure"
            )


        raise


    except Exception:

        logger.exception(
            "DB_AUTH_FAILURE: Failed to retrieve or parse database credentials"
        )

        raise



logger.info(
    "RDS application started"
)


app = Flask(__name__)



@app.route("/")
def home():

    logger.info(
        "Home page requested"
    )

    return """
    <h2>EC2 → RDS Notes App</h2>
    <p>/add?note=test</p>
    <p>/list</p>
    """

@app.route("/init")
def init_db():

    logger.info(
        "Initializing database"
    )

    try:

        creds = get_db_creds()

        conn = pymysql.connect(
            host=creds["host"],
            user=creds["username"],
            password=creds["password"],
            port=int(creds["port"]),
            autocommit=True
        )


        cur = conn.cursor()


        cur.execute(
            f"CREATE DATABASE IF NOT EXISTS `{creds['dbname']}`;"
        )


        cur.execute(
            f"USE `{creds['dbname']}`;"
        )


        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS notes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                note VARCHAR(255) NOT NULL
            );
            """
        )


        cur.close()
        conn.close()


        logger.info(
            "Database initialized successfully"
        )


        return f"Initialized {creds['dbname']} + notes table"


    except Exception:

        logger.exception(
            "DB_INITIALIZATION_FAILURE"
        )

        raise



@app.route("/add", methods=["GET","POST"])
def add_note():

    note = request.args.get(
        "note",
        ""
    ).strip()


    if not note:

        return "Missing note",400


    logger.info(
        "Adding note"
    )


    conn = get_conn()

    cur = conn.cursor()

    cur.execute(
        "INSERT INTO notes(note) VALUES(%s)",
        (note,)
    )


    cur.close()

    conn.close()


    return "Inserted note"



@app.route("/list")
def list_notes():

    logger.info(
        "Listing notes"
    )


    conn = get_conn()

    cur = conn.cursor()


    cur.execute(
        "SELECT id,note FROM notes ORDER BY id DESC"
    )


    rows = cur.fetchall()


    cur.close()

    conn.close()


    return str(rows)



if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=80
    )

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