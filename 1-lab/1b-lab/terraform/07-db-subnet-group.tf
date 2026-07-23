resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "private-db-subnets"
  description = "Private subnets for RDS"

  subnet_ids = [
    aws_subnet.private_subnet_a_resource.id,
    aws_subnet.private_subnet_b_resource.id
  ]

  tags = {
    Name = "private-db-subnets"
  }
}