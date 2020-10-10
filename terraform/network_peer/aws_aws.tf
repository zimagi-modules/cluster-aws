
provider "aws" {
  alias = "network1"
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.network1.region
}

provider "aws" {
  alias = "network2"
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.network2.region
}

resource "aws_vpc_peering_connection" "network1" {
  provider = aws.network1
  vpc_id = var.network1.vpc_id
  peer_vpc_id = var.network2.vpc_id
  peer_region = var.network2.region

  tags = {
    Name = join(":", ["zimagi", var.network1.name, var.network2.name])
    Side = "Requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "network2" {
  provider = aws.network2
  vpc_peering_connection_id = aws_vpc_peering_connection.network1.id
  auto_accept = true

  tags = {
    Name = join(":", ["zimagi", var.network2.name, var.network1.name])
    Side = "Accepter"
  }
}
