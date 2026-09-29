### Private EC2 (Bonus-A)
# Launched into a private subnet that never gets map_public_ip_on_launch,
# so it gets no public IP by default. associate_public_ip_address is set
# explicitly to false anyway, so this is verifiable at a glance rather than
# relying on the subnet default.
resource "aws_instance" "ec2_private" {
  ami                         = "ami-08f44e8eca9095668"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_subnet_a_resource.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_private_profile.name

  user_data = templatefile("${path.module}/26-user-data-private.sh", {
    secret_id           = aws_secretsmanager_secret.db_secret.name
    codeartifact_domain = aws_codeartifact_domain.lab_domain.domain
    codeartifact_owner  = data.aws_caller_identity.current.account_id
    codeartifact_repo   = aws_codeartifact_repository.pip_mirror.repository
    aws_region          = var.aws_region
  })

  vpc_security_group_ids = [aws_security_group.sg_ec2_private_bonus_a.id]

  # Same fix as the public instance: force Terraform to wait for all three
  # policy attachments to finish before launching, so user-data never hits
  # an AccessDeniedException on first boot.
  depends_on = [
    aws_iam_role_policy_attachment.attach_secret_policy_private,
    aws_iam_role_policy_attachment.attach_ssm_managed_policy,
    aws_iam_role_policy.codeartifact_access
  ]

  tags = {
    Name = "ec2_private_bonus_a"
  }
}
