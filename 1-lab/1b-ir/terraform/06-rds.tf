

resource "aws_db_instance" "mysql_rds_db" {
  identifier = "notes-db"

  allocated_storage = 20
  storage_type      = "gp3"

  engine         = "mysql"
  engine_version = "8.4.8"

  instance_class = "db.t3.micro"

  db_name  = "notes_db"
  username = "admin"
  password = "password123" 



  parameter_group_name = "default.mysql8.4"

  publicly_accessible = false

  skip_final_snapshot = true
  deletion_protection = false

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_private_resource.id]
}