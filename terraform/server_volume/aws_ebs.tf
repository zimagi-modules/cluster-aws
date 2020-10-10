
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.server.subnet.network.region
}

resource "aws_ebs_volume" "main" {
  availability_zone = var.server.subnet.zone
  size = var.ebs_size
  type = var.ebs_type
  iops = var.ebs_iops
  encrypted = var.ebs_encrypted

  tags = {
    Name = join(":", ["zimagi", var.server.subnet.network.name, var.server.subnet.name, var.server.name, var.name])
  }
}
output "data_volume_id" {
  value = aws_ebs_volume.main.id
}

resource "aws_volume_attachment" "main" {
  device_name = var.location
  volume_id = aws_ebs_volume.main.id
  instance_id = var.server.instance_id
}
