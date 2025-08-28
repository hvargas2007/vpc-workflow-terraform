variable "vpc_cidr" {
  description = "[REQUIRED] CIDR block for VPC"
  type        = string
  default     = ""

  validation {
    condition     = var.vpc_cidr == "" || can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "vpc_name" {
  description = "Name of the VPC (optional - will be generated if not provided)"
  type        = string
  default     = ""

  validation {
    condition     = var.vpc_name == "" || (length(var.vpc_name) > 0 && length(var.vpc_name) <= 255)
    error_message = "VPC name must be between 1 and 255 characters if provided."
  }

  validation {
    condition     = var.vpc_name == "" || can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*$", var.vpc_name))
    error_message = "VPC name must start with alphanumeric character and can only contain alphanumeric characters and hyphens if provided."
  }
}

variable "azs" {
  description = "List of AZs to use"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.azs) <= 6
    error_message = "Maximum 6 availability zones are supported."
  }
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.public_subnets : can(cidrhost(cidr, 0))])
    error_message = "All public subnet CIDRs must be valid CIDR blocks."
  }
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.private_subnets : can(cidrhost(cidr, 0))])
    error_message = "All private subnet CIDRs must be valid CIDR blocks."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "project_tags" {
  description = "Project-level tags to apply to all resources"
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k, v in var.project_tags : length(k) <= 128 && length(v) <= 256])
    error_message = "Tag keys must be <= 128 characters and values <= 256 characters."
  }

  validation {
    condition     = alltrue([for k in keys(var.project_tags) : can(regex("^[\\w\\s+=.:/@-]*$", k))])
    error_message = "Tag keys can only contain letters, numbers, spaces, and the characters: + - = . _ : / @"
  }
}

variable "create_transit_gateway" {
  description = "Create a Transit Gateway"
  type        = bool
  default     = false
}

variable "transit_gateway_id" {
  description = "ID of existing Transit Gateway to attach to"
  type        = string
  default     = ""

  validation {
    condition     = var.transit_gateway_id == "" || can(regex("^tgw-[a-f0-9]{17}$", var.transit_gateway_id))
    error_message = "Transit Gateway ID must be in the format 'tgw-' followed by 17 hexadecimal characters."
  }
}

variable "attach_to_transit_gateway" {
  description = "Attach VPC to Transit Gateway"
  type        = bool
  default     = false
}

variable "transit_gateway_route_table_id" {
  description = "Transit Gateway Route Table ID for associations"
  type        = string
  default     = ""

  validation {
    condition     = var.transit_gateway_route_table_id == "" || can(regex("^tgw-rtb-[a-f0-9]{17}$", var.transit_gateway_route_table_id))
    error_message = "Transit Gateway Route Table ID must be in the format 'tgw-rtb-' followed by 17 hexadecimal characters."
  }
}

variable "share_transit_gateway" {
  description = "Share Transit Gateway using RAM"
  type        = bool
  default     = false
}

variable "ram_share_principals" {
  description = "List of AWS account IDs, Organization Unit IDs, or Organization ARNs to share Transit Gateway with"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([for principal in var.ram_share_principals :
      can(regex("^\\d{12}$", principal)) ||
      can(regex("^ou-[0-9a-z]{4,32}-[0-9a-z]{8,32}$", principal)) ||
      can(regex("^arn:aws:organizations::[0-9]{12}:ou/o-[a-z0-9]{10,32}/ou-[0-9a-z]{4,32}-[0-9a-z]{8,32}$", principal)) ||
      can(regex("^arn:aws:organizations::[0-9]{12}:organization/o-[a-z0-9]{10,32}$", principal))
    ])
    error_message = "RAM share principals must be valid 12-digit AWS account IDs, Organization Unit IDs (ou-xxxx-xxxxxxxx), Organization Unit ARNs, or Organization ARN."
  }
}

variable "ram_allow_external_principals" {
  description = "Allow external principals (outside of your AWS Organization)"
  type        = bool
  default     = false
}

variable "tgw_attachment_name" {
  description = "Override the default Transit Gateway attachment name"
  type        = string
  default     = ""
}

variable "associate_with_tgw_route_table" {
  description = "Whether to associate the attachment with a specific TGW route table"
  type        = bool
  default     = false
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IPs on launch in public subnets"
  type        = bool
  default     = true
}

variable "nat_gateway_allocation_ids" {
  description = "List of EIP allocation IDs for NAT Gateways"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.nat_gateway_allocation_ids : can(regex("^eipalloc-[a-f0-9]{17}$", id))])
    error_message = "All NAT Gateway allocation IDs must be in the format 'eipalloc-' followed by 17 hexadecimal characters."
  }
}

variable "public_subnet_names" {
  description = "Custom names for public subnets (optional). If not provided, default naming will be used."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for name in var.public_subnet_names : length(name) > 0 && length(name) <= 255])
    error_message = "Subnet names must be between 1 and 255 characters."
  }
}

variable "private_subnet_names" {
  description = "Custom names for private subnets (optional). If not provided, default naming will be used."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for name in var.private_subnet_names : length(name) > 0 && length(name) <= 255])
    error_message = "Subnet names must be between 1 and 255 characters."
  }
}

variable "public_route_table_additional_routes" {
  description = "Additional routes for public route table"
  type = list(object({
    destination_cidr_block    = string
    gateway_id                = optional(string)
    nat_gateway_id            = optional(string)
    transit_gateway_id        = optional(string)
    vpc_endpoint_id           = optional(string)
    vpc_peering_connection_id = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for route in var.public_route_table_additional_routes :
      can(cidrhost(route.destination_cidr_block, 0))
    ])
    error_message = "All destination CIDR blocks must be valid."
  }
}

variable "private_route_table_additional_routes" {
  description = "Additional routes for private route tables"
  type = list(object({
    destination_cidr_block    = string
    gateway_id                = optional(string)
    nat_gateway_id            = optional(string)
    transit_gateway_id        = optional(string)
    vpc_endpoint_id           = optional(string)
    vpc_peering_connection_id = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for route in var.private_route_table_additional_routes :
      can(cidrhost(route.destination_cidr_block, 0))
    ])
    error_message = "All destination CIDR blocks must be valid."
  }
}

variable "create_database_subnets" {
  description = "Create separate database subnets"
  type        = bool
  default     = false
}

variable "database_subnets" {
  description = "List of database subnet CIDRs"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.database_subnets : can(cidrhost(cidr, 0))])
    error_message = "All database subnet CIDRs must be valid CIDR blocks."
  }
}

variable "database_subnet_names" {
  description = "Custom names for database subnets (optional). If not provided, default naming will be used."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for name in var.database_subnet_names : length(name) > 0 && length(name) <= 255])
    error_message = "Subnet names must be between 1 and 255 characters."
  }
}

variable "database_route_table_additional_routes" {
  description = "Additional routes for database route table"
  type = list(object({
    destination_cidr_block    = string
    gateway_id                = optional(string)
    nat_gateway_id            = optional(string)
    transit_gateway_id        = optional(string)
    vpc_endpoint_id           = optional(string)
    vpc_peering_connection_id = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for route in var.database_route_table_additional_routes :
      can(cidrhost(route.destination_cidr_block, 0))
    ])
    error_message = "All destination CIDR blocks must be valid."
  }
}


variable "route_table_prefix" {
  description = "Additional prefix for route table names (e.g., 'inbound' or 'outbound')"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
}

variable "vertical" {
  description = "Business vertical or domain"
  type        = string
}

