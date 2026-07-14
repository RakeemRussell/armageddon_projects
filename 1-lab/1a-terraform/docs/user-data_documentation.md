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
'PY' is the marker that tells Bash where to stop
```

## Python Code

> #the application begins here

---
---
`import json`

```s
The json module allows the Python application to work with JSON (JavaScript Object Notation) data
AWS Secrets Manager returns the secret as a JSON-formatted string. The application uses the json module to convert that string into a Python dictionary so the individual values (such as username, password, and host) can be accessed
```

---
---
`import os`

```s
The os module allows the Python application to interact with the operating system. In this project, it is used to read environment variables that contain configuration values such as the AWS Region, Secrets Manager secret name, RDS endpoint, database name, and database port.
```

---
---
`import boto3`

```s
It simply imports the AWS SDK (Software Development Kit) for Python so the application can communicate with AWS services
The application needs to interact with AWS Secrets Manager to retrieve the database credentials before it can connect to the RDS database.
The boto3 library provides the Python functions needed to make AWS API calls.
```

---
---
`import pymysql`

```s
pymysql is a Python library that allows the application to communicate with a MySQL database using the MySQL protocol
Amazon RDS is running MySQL, so the application needs a MySQL client library to Open a connection to the RDS instance, Send SQL queries, Insert data, Retrieve data and Close the connection
Without pymysql, Python has no built-in ability to talk to a MySQL database
```

---
---
`from flask import Flask, request`

```s
The Flask class is imported so the application can create a Flask web application
Later in the code, this line uses it: app = Flask(__name__)
This creates the web server that listens for HTTP requests and routes them to the correct functions
```

---
---
`REGION = os.environ.get("AWS_REGION", "us-east-1")`

```s
This rule determines which AWS Region the application uses when communicating with AWS services, such as Secrets Manager
It first checks whether an environment variable named AWS_REGION exists.
If it exists, the application uses that value.
If it does not exist, the application defaults to us-east-1.
```

---
---
`SECRET_ID = os.environ.get("SECRET_ID", "lab/rds/mysql")`

```s
creates a Python variable called SECRET_ID
tells the application:
Check if an environment variable named SECRET_ID exists.
If it exists, use that value.
If it does not exist, use the default value: lab/rds/mysql
The application later uses this value here: secrets.get_secret_value(SecretId=SECRET_ID)
which tells AWS Secrets Manager which secret to retrieve.
```

---
---
`secrets = boto3.client("secretsmanager", region_name=REGION)`

```s
creates the AWS SDK client that allows the Python application to communicate with the Secrets Manager API
The application needs this client because the database credentials are not stored in the application code
Instead, they are retrieved securely from AWS Secrets Manager at runtime
```

---
---
`def get_db_creds():`  
    `resp = secrets.get_secret_value(SecretId=SECRET_ID)`  
    `s = json.loads(resp["SecretString"])`  
    # When you use "Credentials for RDS database", AWS usually stores:  
    # username, password, host, port, dbname (sometimes)  
    `return s`
> updated code block to the one below to pass the rds endpoint, database name, and port separately through environment variables

```s
def get_db_creds():
    resp = secrets.get_secret_value(SecretId=SECRET_ID)
    s = json.loads(resp["SecretString"])

    s["host"] = os.environ.get("DB_HOST")
    s["port"] = os.environ.get("DB_PORT", 3306)
    s["dbname"] = os.environ.get("DB_NAME", "notes_db")
    return s
```

```s
resp = secrets.get_secret_value(SecretId=SECRET_ID)
- This retrieves the database credentials stored in AWS Secrets Manager, Instead of hardcoding the username and password into the application, the application requests them at runtime

s = json.loads(resp["SecretString"])
- Secrets Manager returns the secret as a JSON-formatted string

s["host"] = os.environ.get("DB_HOST")
- Terraform knows the RDS endpoint after creating the database, then injects the endpoint as an environment variable

s["port"] = os.environ.get("DB_PORT", 3306)
- The application needs to know which TCP port MySQL is listening on, it defaults to 3306 the standard MySQL port if terraform does not provide one

s["dbname"] = os.environ.get("DB_NAME", "notes_db")
- The application needs to know which database to connect to after authenticating terraform then injects the database name

return s
- returns the dictionary containing all of the information needed to connect to the database such as username, password,host, port, database name
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

> updated to code block below

def get_conn():  
    c = get_db_creds()  
    host = c["host"]  
    user = c["username"]  
    password = c["password"]  
    port = int(c.get("port", 3306))  
    db = c.get("dbname", "notes_db")  
    return pymysql.connect(host=host, user=user, password=password, port=port, database=db, autocommit=True)

```s
c = get_db_creds()
- retrieves the database credentials from the get_db_creds() function

host = c["host"]
- identifies the RDS endpoint.

user = c["username"]
- specifies which database account will authenticate.

password = c["password"]
- authenticates the database user.

port = int(c.get("port", 3306))
- identifies which network port MySQL is listening on, application attempts to read the port from the secret. If no port exists, it defaults to 3306 MySQLs standard listening port

db = c.get("dbname", "notes_db")
- specifies which database to connect to after authentication.
return pymysql.connect(
- creates the network connection from the application to the Amazon RDS MySQL database using the previously retrieved connection parameters
```

---
---
`app = Flask(__name__)`

```s
creates an instance of the Flask web application
The Flask object is the core application container that:
stores routes (/add, /list)
manages HTTP requests and responses
connects URLs to Python functions
handles application configuration
Without creating this object, Flask would not know that this Python file is a web application
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
@app.route("/")
- creates a URL endpoint in the application

def home():
- This function is the logic that executes when the / route receives a request, The function provides the behavior for the endpoint.

return """
<h2>EC2 → RDS Notes App</h2>
<p>POST /add?note=hello</p>
<p>GET /list</p>
"""
- creates the HTTP response sent back to the browser and displays it as a webpage.
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
@app.route("/init")
- creates an HTTP endpoint called /init
- this endpoint is to initialize the database environment by retrieving credentials and preparing the database

def init_db():
- defines the Python function that contains the database initialization logic
- the application executes this function whenever /init receives a request.

c = get_db_creds()
- retrieves the database credentials from AWS Secrets Manager

host = c["host"]
- retrieves the RDS endpoint from the credentials dictionary
-The application needs the database address to know where MySQL is running

user = c["username"]
- Retrieves the MySQL username needed for authentication

password = c["password"]
- Retrieves the database password from Secrets Manager

port = int(c.get("port", 3306))
- Retrieves the database port, If no port exists in the secret, it defaults to 3306
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

> changed Environment=SECRET_ID=lab/rds/mysql to the code block below

WorkingDirectory=/opt/rdsapp  
Environment=SECRET_ID=${secret_id}  
Environment=DB_HOST=${db_host}  
Environment=DB_NAME=${db_name}  
Environment=DB_PORT=3306  
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always

```s
WorkingDirectory=/opt/rdsapp
- tells systemd which directory to switch to before starting the application
Environment=SECRET_ID=${secret_id}
- passes the Secrets Manager secret name from Terraform into the application
Environment=DB_HOST=${db_host}
- Terraform injects the RDS endpoint into the application during deployment
Environment=DB_NAME=${db_name}
- tells the application which database inside MySQL it should use
Environment=DB_PORT=3306
- tells the application which TCP port database is listening on
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
- tells systemd which command to execute when starting the service
Restart=always
- tells systemd to automatically restart the application if it crashes or exits unexpectedly
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
