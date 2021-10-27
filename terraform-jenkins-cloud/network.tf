data "aws_availability_zones" "available" {
  state = "available"
}

# vpc and subnets
resource "aws_vpc" "jenkins" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Terraform = "true"
    Name      = "jenkins-cloud"
  }
}

resource "aws_internet_gateway" "jenkins" {
  vpc_id = aws_vpc.jenkins.id

  tags = {
    Terraform = "true"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.jenkins.id
  cidr_block        = cidrsubnet(aws_vpc.jenkins.cidr_block, 8, 1 + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "PrivateSubnet${1+count.index}-${var.ecs_cluster_name}"
    Tier      = "Private"
    Terraform = "true"
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.jenkins.id
  cidr_block        = cidrsubnet(aws_vpc.jenkins.cidr_block, 8, 3 + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet${1+count.index}-${var.ecs_cluster_name}"
    Tier      = "Public"
    Terraform = "true"
  }
}

# route tables for public and private subnet and internet gateway
# nat gateway has to be in public subnet

resource "aws_route_table" "external" {
  vpc_id = aws_vpc.jenkins.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins.id
  }

  tags = {
    Terraform = "true"
  }
}

resource "aws_route_table_association" "external-jenkins" {
  count = 2
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.external.id
}

# # Unfortunately had to throw nat away because of cost

resource "aws_route_table" "internal" {
  vpc_id = aws_vpc.jenkins.id

  # route {
  #   cidr_block = "0.0.0.0/0"
  #   nat_gateway_id = aws_instance.nat.id
  # }

  tags = {
    Terraform = "true"
  }
}


# resource "aws_nat_gateway" "example" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public[0].id

#   tags = {
#     Name = "NAT"
#   }

#   depends_on = [aws_internet_gateway.example]
# }

# resource "aws_eip" "nat" {
#   vpc      = true
# }

resource "aws_route_table_association" "private" {
  count = 2
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.internal.id
}

# (ノಠ益ಠ)ノ 彡┻━┻ PAID!!!
# discovery to use jenkins master url

# resource "aws_service_discovery_private_dns_namespace" "jenkins" {
#   name = var.ecs_cluster_name
#   vpc = aws_vpc.jenkins.id
# }

# resource "aws_service_discovery_service" "jenkins" {
#   name = "jenkins"

#   dns_config {
#     namespace_id = aws_service_discovery_private_dns_namespace.jenkins.id
#     routing_policy = "MULTIVALUE"
    
#     dns_records {
#       ttl = 60
#       type = "A"
#     }

#     dns_records {
#       ttl  = 60
#       type = "SRV"
#     }
#   }
#   health_check_custom_config {
#     failure_threshold = 5
#   }
# }