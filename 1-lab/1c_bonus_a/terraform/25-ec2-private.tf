### Private EC2 (Bonus-A)
# Launched into a private subnet that never gets map_public_ip_on_launch,
# so it gets no public IP by default. associate_public_ip_address is set
# explicitly to false anyway, so this is verifiable at a glance rather than
# relying on the subnet default.
resource "aws_instance" "ec2_private" {
  ami                         = var.private_ami_id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_subnet_a_resource.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_private_profile.name

  user_data = templatefile("${path.module}/26-user-data-private.sh", {
    secret_id = aws_secretsmanager_secret.db_secret.name
  })

  vpc_security_group_ids = [aws_security_group.sg_ec2_private_bonus_a.id]

  tags = {
    Name = "ec2_private_bonus_a"
  }
}