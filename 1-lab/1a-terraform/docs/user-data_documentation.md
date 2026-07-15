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
conn = pymysql.connect(
- creates a connection from the application running on the EC2 instance to the MySQL database running in Amazon RDS

host=host
- The host parameter tells PyMySQL which MySQL server to connect to. In this project, the value comes from the RDS endpoint
- Without knowing the servers address, Python has no destination for the database connection

user=user
- username identifies which MySQL account is attempting to log in to the database, Then username is retrieved from AWS Secrets Manager

password=password
- password authenticates the database user. MySQL verifies that the supplied password matches the specified username before allowing access

port=port
- port identifies which network service on the RDS instance the application should connect to

autocommit=True
- MySQL groups database changes into transactions. Those changes are not permanently saved until the application explicitly calls commit()
- Setting autocommit=True tells PyMySQL to automatically commit every SQL statement as soon as it successfully completes
```

---
---

`cur = conn.cursor()`

```s
cur = conn.cursor()
- creates a cursor object, which acts as an interface between the Python application and the MySQL database
- A database connection establishes communication with the database server, but it cannot execute SQL statements by itself. The cursor is responsible for sending SQL commands, receiving query results, and managing database operations
- In this project, every SQL statement (CREATE, INSERT, SELECT) is executed through the cursor
```

---
---

`cur.execute("CREATE DATABASE IF NOT EXISTS labdb;")`

```s
cur.execute("CREATE DATABASE IF NOT EXISTS labdb;")
- create a database rule/behavior

CREATE DATABASE labdb;
- This SQL command creates the labdb database where the application will store its data. The application needs a database before it can create tables or insert notes
- Once labdb is selected, every SQL statement that follows is executed against that database unless another database is selected
```

---
---

`cur.execute("USE labdb;")`

```s
- This SQL statement tells MySQL to make labdb the active database for the current connection
- Once labdb is selected, every SQL statement that follows is executed against that database unless another database is selected
```

`cur.execute("""`  
`CREATE TABLE IF NOT EXISTS notes (`  
`id INT AUTO_INCREMENT PRIMARY KEY,`  
`note VARCHAR(255) NOT NULL`  
`);`  
`""")`

```s
CREATE TABLE IF NOT EXISTS notes
- allows the application to create the notes table only if it does not already exist.

id INT AUTO_INCREMENT PRIMARY KEY
- creates a unique identifier for every note.
-INT stores the ID as an integer.
-AUTO_INCREMENT automatically assigns the next available number.
-PRIMARY KEY guarantees every row has a unique identifier
```

---
---

`cur.close()`

```s
cur.close()
- This line closes the database cursor after the SQL operation has finished
- A cursor is the object that sends SQL commands to the database and receives the results. Once the query has completed, the cursor is no longer needed, so it should be closed to release the resources associated with it
- Closing the cursor is considered a best practice because it tells both the Python application and the database that this object is finished being used
```

---
---

`conn.close()`

```s
conn.close()
- This line closes the connection between the application and the MySQL database
- When pymysql.connect() is called, Python opens a network connection to the RDS instance. Once the application finishes using the database, that connection is no longer needed
- Closing the connection:
-Frees resources on the EC2 instance.
-Frees resources on the RDS instance.
-Prevents unused ("idle") database connections from accumulating.
-Signals to MySQL that the session has ended
it is best practice to close database connections as soon as they are finished
```

---
---

`return "Initialized labdb + notes table."`

```s
return "Initialized labdb + notes table."ext
- This line sends a response back to the web browser (the HTTP client) indicating that the /init endpoint completed successfully
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
@app.route("/add", methods=["POST", "GET"])
- This tells the application that whenever a client requests the /add URL using either the GET or POST HTTP method, it should execute the add_note() function

note = request.args.get("note", "").strip()
- retrieves the value of the note query parameter from the URL

if not note:
    return "Missing note param. Try: /add?note=hello", 400
- This validates that the user actually supplied a note before attempting to insert data into the database

conn = get_conn()
- This creates a connection to the RDS MySQL database using the credentials retrieved from AWS Secrets Manager

cur = conn.cursor()
- cursor is the object that sends SQL commands to the database

cur.execute(    "INSERT INTO notes(note) VALUES(%s);",    (note,))
- inserts the users note into the notes table

cur.close()
- releases the cursor resources after the SQL statement finishes

conn.close()
- closes the database connection after the request completes

return f"Inserted note: {note}"
- sends a confirmation message back to the client indicating that the note was successfully inserted

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
def list_notes()
- A function that handles requests to the /list endpoint

@app.route("/list")
- tells the application that whenever a client requests the /list URL, it should execute the list_notes() function

conn = get_conn()
- Creates a connection to the RDS MySQL database

cur = conn.cursor()
- cursor allows Python to send SQL commands to the database and retrieve results.

cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")
- Executes a SQL query that retrieves every note from the notes table

rows = cur.fetchall()
- Retrieves every row returned by the SQL query and stores them in a Python variable

cur.close()
conn.close()
- Releases the cursor and database connection after they are no longer needed

out = "<h3>Notes</h3><ul>"

for r in rows:
    out += f"<li>{r[0]}: {r[1]}</li>"

out += "</ul>"
- Builds an HTML unordered list containing every note returned from the database

return out
- Sends the completed HTML response back to the users web browser
```

---
---

`if __name__ == "__main__":`  
    `app.run(host="0.0.0.0", port=80)`  
`PY`

```S
if __name__ == "__main__":
- This checks whether the Python file is being run directly or imported by another Python file

app.run(host="0.0.0.0", port=80)
- starts the application development server and tells it
-what network interface to listen on
-what port to accept traffic on
Without this line, the application exists but no web server is running.

PY
- a Here Document Terminator Bash rule, not Python
- closes the file-writing block
```

---
---

`cat >/etc/systemd/system/rdsapp.service <<'SERVICE'`

```s
cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
- the beginning of creating a systemd unit file
- Creates a Linux service definition that tells the operating system how to start, manage, restart, and enable the Flask application

/etc/systemd/system/rdsapp.service
- tells Linux where to create the custom systemd service file

<<'SERVICE'
- tells Bash everything until the next SERVICE line should be written into the file
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
Description=EC2 to RDS Notes App
- provides a human-readable description of what the systemd service does
- tells administrators this service runs the application that connects an EC2 instance to an RDS database for storing notes
```

---
---

`After=network.target`

```s
After=network.target
- tells systemds start the rdsapp service only after the basic network target has been reached
- The application depends on network connectivity because it needs to communicate with
-AWS Secrets Manager
-Amazon RDS MySQL
The application cannot function without network access
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
WorkingDirectory=/opt/rdsapp
- tells systemd which directory should be considered the applications working directory when starting the application
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
/usr/bin/python3
- tells systemd which program should execute the application.
- Linux does not automatically know that app.py should run using Python. The service must explicitly specify the interpreter
- this command tells Linux use the Python 3 interpreter installed at /usr/bin/python3 to run the application

/opt/rdsapp/app.py
- specifies the Python file systemd should execute
```

---
---

`Restart=always`

```s
Restart=always
- tells systemd to automatically restart the application whenever the service stops
- improving application availability and removes the need for manual intervention
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
systemctl daemon-reload
- the command exists because systemd does not automatically detect new or modified service files
- daemon-reload forces systemd to:
Scan service directories
Read new service definitions
Detect changes to existing service files
Update its internal configuration


```

`systemctl enable rdsapp`

```s
systemctl enable rdsapp
- configures the rdsapp service to start automatically every time the EC2 instance boots
- ensureing the application is always available after:
An EC2 reboot
A stop/start cycle
A system restart due to maintenance
An unexpected reboot

Without manual intervention
```

---
---

`systemctl start rdsapp`

```s
systemctl start rdsapp
- This command tells systemd (Linuxs service manager) to immediately start the rdsapp service
- The rdsapp service runs the application using the configuration defined in:
/etc/systemd/system/rdsapp.service
- When the command runs, systemd:
Reads the service file.
Sets the working directory.
Loads the environment variables.
Executes: /usr/bin/python3 /opt/rdsapp/app.py

- This starts the application so it can begin accepting HTTP requests on port 80
```
