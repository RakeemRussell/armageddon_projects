#

---
`#!/bin/bash`  

```s
called a shebang, 
#! -> Shebang
/bin/bash -> Path to the Bash interpreter
tells Linux which program should interpret and execute the script
```

---

---
`dnf update -y`

```s
dnf is Amazon Linux 2023 package manager that installs, updates, removes, and manages software
update tells dnf,
Check all installed software packages, compare them to the repos, upgrade anything out of date
-y flag answers yes to the confirmation prompt
```

---
---
`dnf install -y python3-pip`

```s
dnf is Amazon Linux 2023 package manager that installs, updates, removes, and manages software/
install tells dnf - install Pythons package manager (pip) on the EC2 instance/
python3-pip is Pythons package manager/
-y flag answers yes to the confirmation prompt/
```

---
---
`pip3 install flask pymysql boto3`

```s
pip3 is Pythons package manager/
pip3 install tells pip - Download these Python libraries from the Python Package Index (PyPI) and install them on this machine/
pip3 install flask - installs the Flask library so Python programs can use it/
Flask is a Python web framework, allowing Python to receive HTTP request/
After installation Python application can import them, for example - (from flask import Flask)/
pip3 install pymysql - installs PyMySQL/
PyMySQL is a MySQL database driver for Python - allowing Python to communicate with a MySQL database using SQL queries/
pip3 install boto3 - installs AWS SDK/
boto3 is the official AWS SDK for Python - letting Python interact with AWS services through API calls/
```

---
---
`mkdir -p /opt/rdsapp`

```s
Builds application directory
mkdir stands for Make Directory - it creates a folder
-p flag creates parent directories if they dont already exist
/opt is a directory - used for optional or third-party applications that are not part of the operating system itself
/rdsapp is a directory - used to hold the application
```

---
---
`cat >/opt/rdsapp/app.py <<'PY'`

```s
tells Bash - Take everything I type until you see PY, and write it into the file /opt/rdsapp/app.py
> symbol called output redirection - it writes to a file
/opt/rdsapp/app.py - is the destination file
cat >/opt/rdsapp/app.py - means take whatever comes next and save it as app.py
<< called a here-document or heredoc - tells Bash everything after this line belongs to the command until the ending marker


Creating app.py  
This is a here-document
Instead of copying a file,
Bash literally writes everything until PY into app.py
The User Data creates the entire Application
```

## Python Code

> #the application begins here

---
---
`import json`

```s
Converts JSON into Python dictionaries
Secrets Manager returns JSON
```

---
---
`import os`

```s
Reads environment variables, such as SECRET_ID
```

---
---
`import boto3`

```s
AWS SDK
Used to talk to Secrets Manager.
```

---
---
`import pymysql`

```s
Connects to MySQL
```

---
---
`from flask import Flask, request`

```s
Creates the website and lets users send data
```

---
---
`REGION = os.environ.get("AWS_REGION", "us-east-1")`

```s
Reads AWS_REGION, If none exists, defaults to us-east-1
```

---
---
`SECRET_ID = os.environ.get("SECRET_ID", "lab/rds/mysql")`

```s
Use environment variable, otherwise use lab/rds/mysql
```

---
---
`secrets = boto3.client("secretsmanager", region_name=REGION)`

```s
Creates a client object, Later this client calls, get_secret_value()
```

---
---
`def get_db_creds():`  
    `resp = secrets.get_secret_value(SecretId=SECRET_ID)`  
    `s = json.loads(resp["SecretString"])`  
    # When you use "Credentials for RDS database", AWS usually stores:  
    # username, password, host, port, dbname (sometimes)  
    `return s`

```s
This function retrieves credentials
```

---
---
`def get_conn():`
    `c = get_db_creds()`  
    `host = c["host"]`  
    `user = c["username"]`  
    `password = c["password"]`  
    `port = int(c.get("port", 3306))`  
    `db = c.get("dbname", "labdb")` # we'll create this if it doesn't exist  
    `return pymysql.connect(host=host, user=user, password=password, port=port, database=db, autocommit=True)`

```s
Creates a database connection,
Retrieve credentials-> Extract host-> Extract username-> Extract password-> Connect to MySQL-> Return connection object
```

---
---
`app = Flask(__name__)`

```s
Creates the web application.
```

---
---
`@app.route("/")`  
`def home():`  
    `return """`  
    `<h2>EC2 → RDS Notes App</h2>`  
    `<p>POST /add?note=hello</p>`  
    `<p>GET /list</p>`  
    `"""`

```s
Homepage
Returns HTML.
```

---
---
`@app.route("/init")`  
`def init_db():`  
    `c = get_db_creds()`  
    `host = c["host"]`  
    `user = c["username"]`  
    `password = c["password"]`  
    `port = int(c.get("port", 3306))`

```s
Creates the database
Creates the table
This endpoint is only needed once
```

---
---

> #connect without specifying a DB first

`conn = pymysql.connect`(  
    `host=host, user=user,`  
    `password=password,`  
    `port=port,`  
    `autocommit=True`)

```s
This establishes a connection to the MySQL server running on the RDS instance
```

---
---

`cur = conn.cursor()`

```s
Creates a cursor
A cursor lets you send SQL commands
Without a cursor, you cant execute SQL statements
```

---
---

`cur.execute("CREATE DATABASE IF NOT EXISTS labdb;")`

```s
Creates the database
It sends the SQL command: CREATE DATABASE IF NOT EXISTS labdb;
```

---
---

`cur.execute("USE labdb;")`

```s
Now that the database exists, MySQL changes its current working database
Now every SQL command will run inside labdb
```

`cur.execute("""`  
`CREATE TABLE IF NOT EXISTS notes (`  
`id INT AUTO_INCREMENT PRIMARY KEY,`  
`note VARCHAR(255) NOT NULL`  
`);`  
`""")`

```s
This creates the notes table
Column 1,
id INT - An integer
AUTO_INCREMENT - MySQL automatically assigns the next number
PRIMARY KEY - uniquely identifies every row, therefore no two notes can have the same ID.
Column 2,
note VARCHAR(255) - Stores text up to 255 characters
NOT NULL - means note cannot be empty
```

---
---

`cur.close()`

```s
Closes the cursor
when finished sending SQL commands, the cursor is no longer needed
```

---
---

`conn.close()`

```s
Disconnects from MySQL and closes the connection
Leaving connections open wastes database resources and,
over time, can exhaust the maximum number of allowed connections
```

---
---

`return "Initialized labdb + notes table."`

```s
Returns a response
Application sends "Initialized labdb + notes table." text back to the browser
```

---
---

`@app.route("/add", methods=["POST", "GET"])`  
`def add_note():`  
    `note = request.args.get("note", "").strip()`  
    `if not note:`  
        `return "Missing note param. Try: /add?note=hello", 400`  
    `conn = get_conn()`  
    `cur = conn.cursor()`  
    `cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))`  
    `cur.close()`  
    `conn.close()`  
    `return f"Inserted note: {note}"`

```s
Receives ?note=hello
Runs INSERT
Parameterized query, VALUES(%s), protects against SQL Injection
```

---
---

`@app.route("/list")`  
`def list_notes():`  
    `conn = get_conn()`  
    `cur = conn.cursor()`  
    `cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")`  
    `rows = cur.fetchall()`  
    `cur.close()`  
    `conn.close()`  
    `out = "<h3>Notes</h3><ul>"`  
    `for r in rows:`  
        `out += f"<li>{r[0]}: {r[1]}</li>"`  
    `out += "</ul>"`  
    `return out`

```s
Runs SELECT
Returns all rows
Builds HTML
Displays notes
```

---
---

`if __name__ == "__main__":`  
    `app.run(host="0.0.0.0", port=80)`  
`PY`

```S
Run Application
Accept connections from anywhere, on port 80
```

---
---

`cat >/etc/systemd/system/rdsapp.service <<'SERVICE'`

```s
cat, displays the contents of a file
>, operator redirects output into a file
cat >/etc/systemd/system/rdsapp.service, means, take whatever follows and save it into this file
<<'SERVICE', means, everything until you see the word SERVICE should be treated as the contents of the file
```

---
---

`[Unit]`

```s
simply the title of the section, named Unit
```

---
---

`Description=EC2 to RDS Notes App`

```s
simply a human-readable description
It doesnt affect how the service runs, it just helps identify it
```

---
---

`After=network.target`

```s
It tells systemd, do not start this application until the network is available
If the Application started before networking was ready, it would fail
Without a network connection retrieving secrets, RDS connection, HTTP requests, tasks would not work
```

---
---

`[Service]`

```s
simply the title of the section, named Service
```

---
---

`WorkingDirectory=/opt/rdsapp`

```s
tells systemd,
Before starting the application, change into the /opt/rdsapp directory

```

---
---

`Environment=SECRET_ID=lab/rds/mysql`

```s
This creates an environment variable
Before Python starts, Linux creates - SECRET_ID = lab/rds/mysql
Inside Python code, this line reads it - SECRET_ID = os.environ.get("SECRET_ID", "lab/rds/mysql")
os.environ is how Python accesses environment variables provided by the operating system
meaning the service file line and the Python line are connected
```

---
---

`ExecStart=/usr/bin/python3 /opt/rdsapp/app.py`

```s
tells systemd what command to execute to start the service
/usr/bin/python3, is the Python interpreter
/opt/rdsapp/app.py, is the Application
systemd executes this command, Application starts and begins listening on port 80
because code contains, app.run(host="0.0.0.0", port=80)
```

---
---

`Restart=always`

```s
tells systemd, if the application stops for any reason start it again
```

---
---

`[Install]`

```s
simply the title of the section, named Install
```

---
---

`WantedBy=multi-user.target`

```s
tells systemd, Start this service whenever the system reaches the multi-user.target state
multi-user.target means,
-operating system has finished booting
-Networking is available
-Multiple users can log in
-Background services are ready to run
```

---
---

`SERVICE`

```s
Closing marker
A signal that ends the Bash here-document used to create the service file.
It is not written into the rdsapp.service file itself
```

---
---

`systemctl daemon-reload`

```s
tells systemd,
Reload all of the service configuration files because one was added or changed
Without reloading, systemd doesnt know that services added, exists.
```

`systemctl enable rdsapp`

```s
tells Linux, 
Start this service automatically every time the server boots
enable does not start the service immediately, only configures it to start on future boots
```

---
---

`systemctl start rdsapp`

```s
starts the service
It reads the service file and executes - /usr/bin/python3 /opt/rdsapp/app.py
Application begins listening on port 80
```
