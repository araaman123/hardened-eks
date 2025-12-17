resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true 
  enable_dns_support   = true

  tags = { Name = "hardened-eks-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}


# 3. Public Subnet (For Load Balancers - Accessible from outside)
resource "aws_subnet" "public_zone_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true 

  tags = { 
    "Name"                   = "public-us-west-2a"
    "kubernetes.io/role/elb" = "1" # Required for EKS to find public subnets
  }
}

# 4. Private Subnet (The Vault - NO public access)
resource "aws_subnet" "private_zone_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-west-2a"

  tags = { 
    "Name"                            = "private-us-west-2a"
    "kubernetes.io/role/internal-elb" = "1" # Required for EKS internal load balancers
  }
}

# Public Subnet in Second AZ
resource "aws_subnet" "public_zone_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true 

  tags = { 
    "Name"                   = "public-us-west-2b"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private Subnet in Second AZ
resource "aws_subnet" "private_zone_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "us-west-2b"

  tags = { 
    "Name"                            = "private-us-west-2b"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Static IP for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

# The NAT Gateway itself (lives in the PUBLIC subnet)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_zone_a.id

  depends_on = [aws_internet_gateway.igw]
}


# 1. Route Table for the Public Subnet (Direct to Internet)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "public-rt" }
}

# 2. Route Table for the Private Subnet (Goes through NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "private-rt" }
}

# 3. Public Association (Link Subnet to Table)
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_zone_a.id
  route_table_id = aws_route_table.public.id
}

# 4. Private Association (Link Subnet to Table)
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_zone_a.id
  route_table_id = aws_route_table.private.id
}

# Route table associations for zone b
resource "aws_route_table_association" "public_zone_b" {
  subnet_id      = aws_subnet.public_zone_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_zone_b" {
  subnet_id      = aws_subnet.private_zone_b.id
  route_table_id = aws_route_table.private.id
}