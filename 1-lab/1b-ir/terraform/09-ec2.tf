### Public EC2
resource "aws_instance" "ec2_public" {
  ami           = "ami-08f44e8eca9095668"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet_resource.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data = templatefile("${path.module}/10-user-data.sh",{
    secret_id = aws_secretsmanager_secret.db_secret.name
    })
  vpc_security_group_ids = [aws_security_group.sg_ec2_lab.id]
  tags = {
    Name = "ec2_public"
  }
}