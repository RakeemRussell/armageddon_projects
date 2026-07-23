resource "aws_ssm_parameter" "db_endpoint" {
  name  = "db_endpoint_parameter"
  type  = "String"
  value = aws_db_instance.mysql_rds_db.address
}

resource "aws_ssm_parameter" "db_port" {
  name  = "db_port_parameter"
  type  = "String"
  value = tostring(aws_db_instance.mysql_rds_db.port)
}

resource "aws_ssm_parameter" "db_name" {
  name  = "db_name_parameter"
  type  = "String"
  value = aws_db_instance.mysql_rds_db.db_name
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name  = "cloudwatch_agent_parameter"
  type  = "String"
  value = file("${path.module}/16-cloudwatch-agent-config.json")
}