locals {
  vpc_id                  = aws_vpc.this.id
  create_internet_gateway = length(var.public_subnets) > 0
  nat_gateway_count       = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    var.project_tags,
    {
      Name = var.vpc_name != "" ? var.vpc_name : "vpc-${var.vertical}-${var.environment}"
    }
  )
}

resource "aws_internet_gateway" "this" {
  count = local.create_internet_gateway ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    var.project_tags,
    {
      Name = "igw-${var.vertical}-${var.environment}"
    }
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = local.vpc_id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    var.project_tags,
    {
      Name = "subnet-public-${var.vertical}-${var.environment}-${count.index + 1}"
      Type = "public"
    }
  )
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = local.vpc_id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    var.project_tags,
    {
      Name = "subnet-private-${var.vertical}-${var.environment}-${count.index + 1}"
      Type = "private"
    }
  )
}

resource "aws_eip" "nat" {
  count = length(var.public_subnets) > 0 ? local.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(
    var.project_tags,
    {
      Name = "eip-nat-${var.vertical}-${var.environment}-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = length(var.public_subnets) > 0 ? local.nat_gateway_count : 0

  allocation_id = length(var.nat_gateway_allocation_ids) > 0 ? var.nat_gateway_allocation_ids[count.index] : aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[var.single_nat_gateway ? 0 : count.index].id

  tags = merge(
    var.project_tags,
    {
      Name = "nat-${var.vertical}-${var.environment}-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    var.project_tags,
    {
      Name = "rt-public-${var.vertical}-${var.environment}"
    }
  )
}

resource "aws_route" "public_internet_gateway" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  count = length(var.private_subnets) > 0 ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0

  vpc_id = local.vpc_id

  tags = merge(
    var.project_tags,
    {
      Name = var.single_nat_gateway ? "rt-private-${var.vertical}-${var.environment}" : "rt-private-${var.vertical}-${var.environment}-${var.azs[count.index]}"
    }
  )
}

resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? length(aws_route_table.private) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index % length(aws_route_table.private)].id
}

resource "aws_ec2_transit_gateway" "this" {
  count = var.create_transit_gateway ? 1 : 0

  description                     = "Transit Gateway ${var.vertical}-${var.environment}"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = merge(
    var.project_tags,
    {
      Name = "tgw-${var.vertical}-${var.environment}"
    }
  )
}

resource "aws_ram_resource_share" "tgw" {
  count = var.share_transit_gateway && var.create_transit_gateway ? 1 : 0

  name                      = "ram-share-tgw-${var.vertical}-${var.environment}"
  allow_external_principals = var.ram_allow_external_principals

  tags = merge(
    var.project_tags,
    {
      Name = "ram-share-tgw-${var.vertical}-${var.environment}"
    }
  )
}

resource "aws_ram_resource_association" "tgw" {
  count = var.share_transit_gateway && var.create_transit_gateway ? 1 : 0

  resource_arn       = aws_ec2_transit_gateway.this[0].arn
  resource_share_arn = aws_ram_resource_share.tgw[0].arn
}

resource "aws_ram_principal_association" "tgw" {
  count = var.share_transit_gateway && var.create_transit_gateway ? length(var.ram_share_principals) : 0

  principal          = var.ram_share_principals[count.index]
  resource_share_arn = aws_ram_resource_share.tgw[0].arn
}

locals {
  tgw_id                 = var.create_transit_gateway ? aws_ec2_transit_gateway.this[0].id : var.transit_gateway_id
  tgw_attachment_subnets = length(var.private_subnets) > 0 ? aws_subnet.private[*].id : aws_subnet.public[*].id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count = var.attach_to_transit_gateway ? 1 : 0

  subnet_ids         = local.tgw_attachment_subnets
  transit_gateway_id = local.tgw_id
  vpc_id             = local.vpc_id

  tags = merge(
    var.project_tags,
    {
      Name = "tgw-attach-${var.vertical}-${var.environment}"
    }
  )
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  count = var.attach_to_transit_gateway && var.transit_gateway_route_table_id != "" ? 1 : 0

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

resource "aws_subnet" "database" {
  count = var.create_database_subnets ? length(var.database_subnets) : 0

  vpc_id            = local.vpc_id
  cidr_block        = var.database_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    var.project_tags,
    {
      Name = "subnet-database-${var.vertical}-${var.environment}-${count.index + 1}"
      Type = "database"
    }
  )
}

resource "aws_route_table" "database" {
  count = var.create_database_subnets && length(var.database_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    var.project_tags,
    {
      Name = "rt-database-${var.vertical}-${var.environment}"
    }
  )
}

resource "aws_route_table_association" "database" {
  count = var.create_database_subnets ? length(var.database_subnets) : 0

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

resource "aws_route" "public_additional" {
  for_each = { for idx, route in var.public_route_table_additional_routes : idx => route if length(var.public_subnets) > 0 }

  route_table_id            = aws_route_table.public[0].id
  destination_cidr_block    = each.value.destination_cidr_block
  gateway_id                = each.value.gateway_id
  nat_gateway_id            = each.value.nat_gateway_id
  transit_gateway_id        = each.value.transit_gateway_id
  vpc_endpoint_id           = each.value.vpc_endpoint_id
  vpc_peering_connection_id = each.value.vpc_peering_connection_id
}

resource "aws_route" "private_additional" {
  for_each = {
    for item in flatten([
      for rt_idx, rt in aws_route_table.private : [
        for route_idx, route in var.private_route_table_additional_routes : {
          key                       = "${rt_idx}-${route_idx}"
          route_table_id            = rt.id
          destination_cidr_block    = route.destination_cidr_block
          gateway_id                = route.gateway_id
          nat_gateway_id            = route.nat_gateway_id
          transit_gateway_id        = route.transit_gateway_id
          vpc_endpoint_id           = route.vpc_endpoint_id
          vpc_peering_connection_id = route.vpc_peering_connection_id
        }
      ]
    ]) : item.key => item
  }

  route_table_id            = each.value.route_table_id
  destination_cidr_block    = each.value.destination_cidr_block
  gateway_id                = each.value.gateway_id
  nat_gateway_id            = each.value.nat_gateway_id
  transit_gateway_id        = each.value.transit_gateway_id
  vpc_endpoint_id           = each.value.vpc_endpoint_id
  vpc_peering_connection_id = each.value.vpc_peering_connection_id
}

resource "aws_route" "database_additional" {
  for_each = { for idx, route in var.database_route_table_additional_routes : idx => route if var.create_database_subnets && length(var.database_subnets) > 0 }

  route_table_id            = aws_route_table.database[0].id
  destination_cidr_block    = each.value.destination_cidr_block
  gateway_id                = each.value.gateway_id
  nat_gateway_id            = each.value.nat_gateway_id
  transit_gateway_id        = each.value.transit_gateway_id
  vpc_endpoint_id           = each.value.vpc_endpoint_id
  vpc_peering_connection_id = each.value.vpc_peering_connection_id
}