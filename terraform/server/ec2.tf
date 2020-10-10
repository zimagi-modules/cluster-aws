
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.subnet.network.region
}

resource "aws_instance" "server" {
  subnet_id = var.subnet.subnet_id
  ami = var.image
  instance_type = var.machine
  tenancy = var.tenancy
  ebs_optimized = var.ebs_optimized
  monitoring = var.monitoring
  associate_public_ip_address = var.subnet.use_public_ip

  key_name = var.key_name
  vpc_security_group_ids = var.security_groups

  root_block_device {
    delete_on_termination = "true"
    volume_size = var.ebs_size
    volume_type = var.ebs_type
    iops = var.ebs_iops
  }

  tags = {
    Name = join(":", ["zimagi", var.subnet.network.name, var.subnet.name, var.name])
  }
}
resource "aws_eip" "server_ip" {
  count = var.subnet.use_public_ip ? 1 : 0
  instance = aws_instance.server.id
  vpc = true

  tags = {
    Name = join(":", ["zimagi", var.subnet.network.name, var.subnet.name, var.name])
  }
}

output "instance_id" {
  value = aws_instance.server.id
}
output "private_ip_address" {
  value = aws_instance.server.private_ip
}
output "public_ip_address" {
  value = var.subnet.use_public_ip ? aws_eip.server_ip.0.public_ip : null
}
