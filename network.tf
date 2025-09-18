# Get all available AZs dynamically
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "ALL" {
  cidr_block = var.ALL-VPC-INFO.vpc-cidr
  tags = {
    Name = "ALL"
  }
}


resource "aws_internet_gateway" "IGW" {
  vpc_id = local.vpc-id ## REDUSING THE EXPRESSION SIZE

  tags = {
    Name = "IGW"
  }
}

resource "aws_route_table" "public" {
  vpc_id = local.vpc-id ## REDUSING THE EXPRISSION SIZE
  route {
    cidr_block = local.anywhere ## REDUSING THE EXPRISSION SIZE
    gateway_id = aws_internet_gateway.IGW.id
  }
  tags = {
    Name = "public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = local.vpc-id ## REDUSING THE EXPRISSION SIZE
  tags = {
    Name = "private"
  }
}


# ------------------------------
# Public Subnets (first half of AZs)
# ------------------------------
resource "aws_subnet" "public" {
  count             = local.half
  vpc_id            = aws_vpc.ALL.id
  cidr_block        = cidrsubnet(var.ALL-VPC-INFO.vpc-cidr, 8, count.index)
  availability_zone = local.az_list[count.index]

  tags = {
    Name = "public-${count.index + 1}"
    Type = "public"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = local.half
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ------------------------------
# Private Subnets (second half of AZs)
# ------------------------------
resource "aws_subnet" "private" {
  count             = length(local.az_list) - local.half
  vpc_id            = aws_vpc.ALL.id
  #cidr_block        = cidrsubnet(var.ALL-VPC-INFO.vpc-cidr, 8, count.index)
  #cidr_block       = cidrsubnet(var.ALL_VPC_INFO.vpc_cidr, 8, count.index + length(var.ALL_VPC_INFO.public_subnets))
  cidr_block        = cidrsubnet(var.ALL-VPC-INFO.vpc-cidr, 8, count.index + local.half)
  availability_zone = local.az_list[count.index + local.half]

  tags = {
    Name = "private-${count.index + 1}"
    Type = "private"
  }
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(local.az_list) - local.half
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
