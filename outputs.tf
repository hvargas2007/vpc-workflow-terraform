output "vpc_id" {
  description = "The ID of the VPC"
  value       = local.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public IPs of NAT Gateways"
  value       = aws_nat_gateway.this[*].public_ip
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : null
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : null
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private[*].id
}

output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.this[0].id : var.transit_gateway_id
}

output "transit_gateway_arn" {
  description = "The ARN of the Transit Gateway"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.this[0].arn : null
}

output "transit_gateway_attachment_id" {
  description = "The ID of the Transit Gateway VPC attachment"
  value       = var.attach_to_transit_gateway ? aws_ec2_transit_gateway_vpc_attachment.this[0].id : null
}

output "ram_resource_share_arn" {
  description = "The ARN of the RAM resource share for Transit Gateway"
  value       = var.share_transit_gateway && var.create_transit_gateway ? aws_ram_resource_share.tgw[0].arn : null
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_cidrs" {
  description = "List of CIDR blocks of database subnets"
  value       = aws_subnet.database[*].cidr_block
}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = length(aws_route_table.database) > 0 ? aws_route_table.database[0].id : null
}