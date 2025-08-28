# Módulo VPC

Este módulo crea una VPC de AWS completa con subnets públicas/privadas, NAT Gateways, Internet Gateway y opcionalmente se conecta a un Transit Gateway.

## Descripción

El módulo VPC permite crear:
- VPC con CIDR configurable
- Subnets públicas (con Internet Gateway)
- Subnets privadas (con NAT Gateway opcional)
- Subnets de base de datos (aisladas)
- Tablas de rutas con rutas adicionales configurables
- Attachment a Transit Gateway
- Alta disponibilidad multi-AZ

## Uso

### Opción 1: VPC Simple usando terraform.tfvars

```hcl
# terraform.tfvars
vpc_cidr = "10.0.0.0/16"
public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
enable_nat_gateway = true
single_nat_gateway = false
```

```hcl
# main.tf
module "mi_vpc" {
  source = "./modules/vpc"
  
  # CIDR y Subnets - desde variables
  vpc_cidr        = var.vpc_cidr
  azs             = var.availability_zones
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  
  # NAT Gateway
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  
  # Configuración DNS
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Tags
  project_tags = var.project_tags
  
  # Naming
  environment = "produccion"
  vertical    = var.vertical
}
```

### Opción 2: Múltiples VPCs 

```hcl
# VPC Outbound - Con NAT para salida a Internet
module "outbound" {
  source = "./modules/vpc"
  
  # CIDR y Subnets hardcodeados
  vpc_cidr = "10.1.0.0/16"
  azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Subnets públicas para NAT Gateways
  public_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  
  # Subnets privadas para workloads
  private_subnets = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
  
  # NAT Gateway en cada AZ para alta disponibilidad
  enable_nat_gateway = true
  single_nat_gateway = false
  
  # Transit Gateway
  attach_to_transit_gateway = true
  transit_gateway_id        = module.transit_gateway.transit_gateway_id
  
  # Rutas adicionales via Transit Gateway
  private_route_table_additional_routes = [
    {
      destination_cidr_block = "10.0.0.0/16"
      transit_gateway_id     = module.transit_gateway.transit_gateway_id
    }
  ]
  
  # Configuración
  map_public_ip_on_launch = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  
  # Tags y naming
  project_tags = var.project_tags
  environment  = "outbound"
  vertical     = "LATAM"
}

# VPC Inbound - Solo con Internet Gateway
module "inbound" {
  source = "./modules/vpc"
  
  vpc_cidr       = "10.0.0.0/16"
  azs            = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  
  # Sin NAT Gateway - solo IGW
  enable_nat_gateway = false
  
  # Transit Gateway
  attach_to_transit_gateway = true
  transit_gateway_id        = module.transit_gateway.transit_gateway_id
  
  # Configuración
  map_public_ip_on_launch = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  
  # Tags y naming
  project_tags = var.project_tags
  environment  = "inbound"
  vertical     = "LATAM"
}
```

## Variables

### Variables de Red Principales

| Variable | Descripción | Tipo | Default | Ejemplo |
|----------|-------------|------|---------|---------|
| `vpc_cidr` | CIDR block de la VPC | `string` | **requerido** | `"10.0.0.0/16"` |
| `vpc_name` | Nombre de la VPC (opcional) | `string` | `""` | `"vpc-produccion"` |
| `azs` | Lista de zonas de disponibilidad | `list(string)` | `[]` | `["us-east-1a", "us-east-1b"]` |

### Variables de Subnets

| Variable | Descripción | Tipo | Default | Notas |
|----------|-------------|------|---------|--------|
| `public_subnets` | CIDRs de subnets públicas | `list(string)` | `[]` | Una por AZ |
| `private_subnets` | CIDRs de subnets privadas | `list(string)` | `[]` | Una por AZ |
| `database_subnets` | CIDRs de subnets de BD | `list(string)` | `[]` | Opcional |
| `create_database_subnets` | Crear subnets de BD | `bool` | `false` | Para RDS |

### Variables de NAT Gateway

| Variable | Descripción | Tipo | Default | Cuándo usar |
|----------|-------------|------|---------|-------------|
| `enable_nat_gateway` | Habilitar NAT Gateway | `bool` | `false` | `true` para salida a Internet desde subnets privadas |
| `single_nat_gateway` | Usar solo un NAT | `bool` | `false` | `true` para ahorrar costos (menos HA) |
| `nat_gateway_allocation_ids` | EIPs existentes para NAT | `list(string)` | `[]` | Si tienes EIPs reservadas |

### Variables de Transit Gateway

| Variable | Descripción | Tipo | Default |
|----------|-------------|------|---------|
| `attach_to_transit_gateway` | Crear attachment a TGW | `bool` | `false` |
| `transit_gateway_id` | ID del Transit Gateway | `string` | `""` |
| `transit_gateway_route_table_id` | ID de tabla de rutas TGW | `string` | `""` |

### Variables de Rutas Adicionales

| Variable | Descripción | Tipo | Default |
|----------|-------------|------|---------|
| `public_route_table_additional_routes` | Rutas extras para tabla pública | `list(object)` | `[]` |
| `private_route_table_additional_routes` | Rutas extras para tablas privadas | `list(object)` | `[]` |
| `database_route_table_additional_routes` | Rutas extras para tabla de BD | `list(object)` | `[]` |

Estructura de rutas adicionales:
```hcl
[
  {
    destination_cidr_block    = "10.0.0.0/8"
    transit_gateway_id        = "tgw-xxxxx"     # Una de estas
    gateway_id                = "igw-xxxxx"     # opciones
    nat_gateway_id           = "nat-xxxxx"     # debe estar
    vpc_endpoint_id          = "vpce-xxxxx"    # presente
    vpc_peering_connection_id = "pcx-xxxxx"
  }
]
```

### Variables de Configuración

| Variable | Descripción | Tipo | Default |
|----------|-------------|------|---------|
| `enable_dns_hostnames` | Habilitar hostnames DNS | `bool` | `true` |
| `enable_dns_support` | Habilitar soporte DNS | `bool` | `true` |
| `map_public_ip_on_launch` | Auto-asignar IPs públicas | `bool` | `true` |

### Variables de Identificación

| Variable | Descripción | Tipo | Default | Ejemplo |
|----------|-------------|------|---------|---------|
| `project_tags` | Tags del proyecto | `map(string)` | `{}` | `{ Team = "Platform" }` |
| `environment` | Ambiente (para nombres) | `string` | **requerido** | `"production"` |
| `vertical` | Vertical de negocio | `string` | **requerido** | `"LATAM"` |

## Outputs

| Output | Descripción | Uso típico |
|--------|-------------|------------|
| `vpc_id` | ID de la VPC | Para Security Groups |
| `vpc_cidr_block` | CIDR de la VPC | Para reglas de firewall |
| `public_subnet_ids` | IDs de subnets públicas | Para ALBs |
| `private_subnet_ids` | IDs de subnets privadas | Para EC2/ECS |
| `database_subnet_ids` | IDs de subnets de BD | Para RDS |
| `nat_gateway_ids` | IDs de NAT Gateways | Referencia |
| `internet_gateway_id` | ID del IGW | Referencia |
| `public_route_table_id` | ID tabla rutas pública | Para rutas custom |
| `private_route_table_ids` | IDs tablas rutas privadas | Para rutas custom |
| `transit_gateway_attachment_id` | ID del TGW attachment | Para asociaciones |

## Casos de Uso Comunes

### 1. VPC para Aplicación Web
```hcl
module "vpc_app" {
  source = "./modules/vpc"
  
  vpc_cidr        = "10.10.0.0/16"
  azs             = data.aws_availability_zones.available.names
  public_subnets  = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  private_subnets = ["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true  # Un solo NAT para dev/test
  
  environment = "desarrollo"
  vertical    = "ecommerce"
}
```

### 2. VPC Pirvate
```hcl
module "vpc_private" {
  source = "./modules/vpc"
  
  vpc_cidr         = "10.20.0.0/16"
  azs              = ["us-east-1a", "us-east-1b"]
  private_subnets  = ["10.20.1.0/24", "10.20.2.0/24"]
  database_subnets = ["10.20.101.0/24", "10.20.102.0/24"]
  
  create_database_subnets = true
  enable_nat_gateway      = false  # BDs no necesitan Internet
  
  environment = "database"
  vertical    = "core"
}
```

### 3. VPC DMZ con Transit Gateway
```hcl
module "vpc_dmz" {
  source = "./modules/vpc"
  
  vpc_cidr       = "10.30.0.0/16"
  azs            = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]
  
  # Conectar a Transit Gateway
  attach_to_transit_gateway = true
  transit_gateway_id        = data.aws_ec2_transit_gateway.main.id
  
  # Rutas a redes internas
  public_route_table_additional_routes = [
    {
      destination_cidr_block = "10.0.0.0/8"
      transit_gateway_id     = data.aws_ec2_transit_gateway.main.id
    }
  ]
  
  environment = "dmz"
  vertical    = "security"
}
```
