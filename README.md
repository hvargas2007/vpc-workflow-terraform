# Módulo Terraform para AWS VPC

[![Licencia: MIT](https://img.shields.io/badge/Licencia-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=flat&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![GitHub release](https://img.shields.io/github/release/hvargas2007/vpc-workflow-terraform.svg)](https://github.com/hvargas2007/vpc-workflow-terraform/releases/)

Un módulo Terraform completo y listo para producción para crear entornos AWS Virtual Private Cloud (VPC) altamente configurables. Este módulo soporta múltiples arquitecturas de red incluyendo subnets privadas, subnets de base de datos, integración con Transit Gateway y configuraciones de enrutamiento personalizadas.

## 🎯 Visión General

Este módulo proporciona un enfoque flexible y escalable para la creación de VPC en AWS con soporte para:
- Arquitecturas de red multi-capa
- Conectividad con Transit Gateway
- Configuraciones de rutas personalizadas
- Grupos de subnets para bases de datos
- Integración con VPN y Direct Connect
- Soporte completo IPv4/IPv6

## 📋 Tabla de Contenidos

- [Características](#características)
- [Requisitos Previos](#requisitos-previos)
- [Inicio Rápido](#inicio-rápido)
- [Uso del Módulo](#uso-del-módulo)
- [Patrones de Arquitectura](#patrones-de-arquitectura)
- [Variables de Entrada](#variables-de-entrada)
- [Outputs](#outputs)
- [Ejemplos](#ejemplos)
- [Seguridad](#seguridad)
- [Contribuir](#contribuir)
- [Licencia](#licencia)

## ✨ Características

### Componentes de Red
- **Creación de VPC**: Bloques CIDR configurables con soporte DNS
- **Gestión de Subnets**: Creación de subnets privadas y de base de datos en múltiples AZs
- **Enrutamiento**: Configuración flexible de tablas de rutas con rutas personalizadas
- **Transit Gateway**: Soporte nativo para conexiones AWS Transit Gateway
- **NAT Gateway**: NAT Gateway opcional para acceso a internet saliente
- **Grupos de Seguridad**: Configuración de grupos de seguridad por defecto
- **Flow Logs**: Soporte para VPC Flow Logs para monitoreo de red

### Capacidades Avanzadas
- **Soporte Multi-Región**: Despliega en cualquier región de AWS
- **Alta Disponibilidad**: Despliegue automático multi-AZ
- **Etiquetado Personalizado**: Estrategia completa de etiquetado de recursos
- **Integración IPAM**: Soporte para AWS IP Address Manager
- **Network ACLs**: Listas de control de acceso a red personalizables
- **VPC Endpoints**: Soporte para endpoints de servicios AWS

## 🔧 Requisitos Previos

- Terraform >= 1.0
- AWS Provider >= 4.0
- Cuenta AWS con permisos IAM apropiados
- Comprensión de conceptos de networking en AWS

### Permisos IAM Requeridos

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*Vpc*",
        "ec2:*Subnet*",
        "ec2:*Route*",
        "ec2:*InternetGateway*",
        "ec2:*NatGateway*",
        "ec2:*TransitGateway*",
        "ec2:*SecurityGroup*",
        "ec2:*NetworkAcl*",
        "ec2:*FlowLogs*",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeRegions",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🚀 Inicio Rápido

### VPC Básica con Subnets Privadas

```hcl
module "vpc" {
  source = "git::https://github.com/hvargas2007/vpc-workflow-terraform?ref=v1.0.0"

  vpc_cidr = "10.0.0.0/16"
  vpc_name = "mi-vpc"
  
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  
  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  project_tags = {
    Environment = "produccion"
    Project     = "mi-proyecto"
  }
}
```

## 📘 Uso del Módulo

### Ejemplo Completo con Todas las Características

```hcl
module "vpc" {
  source = "git::https://github.com/hvargas2007/vpc-workflow-terraform?ref=v1.0.0"

  # Configuración de VPC
  vpc_cidr             = "10.0.0.0/16"
  vpc_name             = "vpc-produccion"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Zonas de Disponibilidad
  azs = data.aws_availability_zones.available.names
  
  # Configuración de Subnets
  private_subnets          = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  create_database_subnets  = true
  database_subnets         = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  # NAT Gateway
  enable_nat_gateway = true
  single_nat_gateway = false  # Un NAT por AZ para HA
  
  # Transit Gateway
  attach_to_transit_gateway = true
  transit_gateway_id        = "tgw-0123456789abcdef0"
  
  # Rutas Personalizadas
  private_route_table_additional_routes = [
    {
      destination_cidr_block = "192.168.0.0/16"
      transit_gateway_id     = "tgw-0123456789abcdef0"
    }
  ]
  
  # Etiquetas
  project_tags = {
    Environment = "produccion"
    CostCenter  = "ingenieria"
    ManagedBy   = "terraform"
  }
  
  environment = "prod"
  vertical    = "plataforma"
}
```

## 🏗️ Patrones de Arquitectura

### 1. VPC Privada Simple

Perfecta para aplicaciones internas sin acceso a internet:

```hcl
module "vpc_privada" {
  source = "git::https://github.com/hvargas2007/vpc-workflow-terraform?ref=v1.0.0"
  
  vpc_cidr        = "10.0.0.0/16"
  vpc_name        = "vpc-privada"
  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  
  enable_nat_gateway = false  # Sin acceso a internet
}
```

### 2. Arquitectura Multi-Capa

Para aplicaciones que requieren capas separadas de base de datos y aplicación:

```hcl
module "vpc_multicapa" {
  source = "git::https://github.com/hvargas2007/vpc-workflow-terraform?ref=v1.0.0"
  
  vpc_cidr = "10.0.0.0/16"
  vpc_name = "vpc-multicapa"
  
  azs                     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets         = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  create_database_subnets = true
  database_subnets        = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true  # Optimización de costos
}
```

### 3. Hub-and-Spoke con Transit Gateway

Para redes a escala empresarial:

```hcl
module "vpc_spoke" {
  source = "git::https://github.com/hvargas2007/vpc-workflow-terraform?ref=v1.0.0"
  
  vpc_cidr = "10.1.0.0/16"
  vpc_name = "vpc-spoke-1"
  
  azs             = ["ap-southeast-1a", "ap-southeast-1b"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  
  attach_to_transit_gateway = true
  transit_gateway_id        = aws_ec2_transit_gateway.main.id
  
  # Rutas a otras VPCs vía Transit Gateway
  private_route_table_additional_routes = [
    {
      destination_cidr_block = "10.0.0.0/8"
      transit_gateway_id     = aws_ec2_transit_gateway.main.id
    },
    {
      destination_cidr_block = "172.16.0.0/12"
      transit_gateway_id     = aws_ec2_transit_gateway.main.id
    }
  ]
}
```

### 4. Arquitectura DMZ

Para aplicaciones públicas con servicios backend:

```hcl
module "vpc_dmz" {
  source = "git::https://github.com/hvargas2007/vpc-workflow-terraform?ref=v1.0.0"
  
  vpc_cidr = "10.0.0.0/16"
  vpc_name = "vpc-dmz"
  
  azs              = ["us-east-1a", "us-east-1b"]
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]    # Capa DMZ
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24"]  # Capa de aplicación
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24"]  # Capa de datos
  
  enable_nat_gateway      = true
  create_database_subnets = true
}
```

## 📊 Variables de Entrada

### Variables Requeridas

| Nombre | Descripción | Tipo | Ejemplo |
|--------|-------------|------|---------|
| `vpc_cidr` | Bloque CIDR para la VPC | `string` | `"10.0.0.0/16"` |
| `vpc_name` | Nombre de la VPC | `string` | `"mi-vpc"` |
| `azs` | Lista de zonas de disponibilidad | `list(string)` | `["us-east-1a", "us-east-1b"]` |
| `private_subnets` | Lista de bloques CIDR para subnets privadas | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` |

### Variables Opcionales

| Nombre | Descripción | Tipo | Por Defecto |
|--------|-------------|------|-------------|
| `enable_dns_hostnames` | Habilitar hostnames DNS en VPC | `bool` | `true` |
| `enable_dns_support` | Habilitar soporte DNS en VPC | `bool` | `true` |
| `enable_nat_gateway` | Crear NAT Gateway para subnets privadas | `bool` | `false` |
| `single_nat_gateway` | Usar un solo NAT Gateway para todas las AZs | `bool` | `false` |
| `create_database_subnets` | Crear grupo de subnets de base de datos | `bool` | `false` |
| `database_subnets` | Lista de bloques CIDR para subnets de BD | `list(string)` | `[]` |
| `attach_to_transit_gateway` | Conectar VPC a Transit Gateway | `bool` | `false` |
| `transit_gateway_id` | ID del Transit Gateway para conexión | `string` | `""` |
| `create_transit_gateway` | Crear nuevo Transit Gateway | `bool` | `false` |
| `private_route_table_additional_routes` | Rutas adicionales para subnets privadas | `list(map(string))` | `[]` |
| `database_route_table_additional_routes` | Rutas adicionales para subnets de BD | `list(map(string))` | `[]` |
| `project_tags` | Etiquetas para aplicar a todos los recursos | `map(string)` | `{}` |
| `environment` | Nombre del ambiente | `string` | `"dev"` |
| `vertical` | Vertical de negocio o equipo | `string` | `""` |

## 📤 Outputs

| Nombre | Descripción |
|--------|-------------|
| `vpc_id` | ID de la VPC |
| `vpc_cidr_block` | Bloque CIDR de la VPC |
| `private_subnet_ids` | Lista de IDs de subnets privadas |
| `private_subnet_cidrs` | Lista de bloques CIDR de subnets privadas |
| `database_subnet_ids` | Lista de IDs de subnets de base de datos |
| `database_subnet_group_name` | Nombre del grupo de subnets de BD |
| `private_route_table_ids` | Lista de IDs de tablas de rutas privadas |
| `database_route_table_ids` | Lista de IDs de tablas de rutas de BD |
| `nat_gateway_ids` | Lista de IDs de NAT Gateways |
| `transit_gateway_attachment_id` | ID de conexión a Transit Gateway |
| `vpc_flow_log_id` | ID del VPC Flow Log |
| `default_security_group_id` | ID del grupo de seguridad por defecto |

## 🔐 Seguridad

### Mejores Prácticas

1. **Segmentación de Red**: Usa subnets separadas para diferentes capas de aplicación
2. **Subnets Privadas**: Mantén recursos sensibles en subnets privadas sin acceso directo a internet
3. **Grupos de Seguridad**: Implementa reglas de grupos de seguridad con menor privilegio
4. **NACLs**: Usa Network ACLs para seguridad adicional a nivel de subnet
5. **Flow Logs**: Habilita VPC Flow Logs para monitoreo de red
6. **Cifrado**: Usa volúmenes EBS y buckets S3 cifrados
7. **Transit Gateway**: Centraliza la conectividad para mejor control de seguridad

### Características de Cumplimiento

- **HIPAA**: Aislamiento de red y soporte de cifrado
- **PCI DSS**: Capacidades de segmentación de red
- **SOC2**: Registro de auditoría vía Flow Logs
- **GDPR**: Control de residencia de datos mediante selección de región

## 📚 Ejemplos

### Ejemplo 1: Ambiente de Desarrollo

```hcl
module "vpc_dev" {
  source = "git::https://github.com/hvargas2007/vpc-workflow-terraform?ref=v1.0.0"
  
  vpc_cidr        = "10.10.0.0/16"
  vpc_name        = "vpc-desarrollo"
  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true  # Ahorro de costos en dev
  
  project_tags = {
    Environment = "desarrollo"
    AutoShutdown = "true"
  }
}
```

### Ejemplo 2: Producción con Alta Disponibilidad

```hcl
module "vpc_prod" {
  source = "git::https://github.com/hvargas2007/vpc-workflow-terraform?ref=v1.0.0"
  
  vpc_cidr = "10.0.0.0/16"
  vpc_name = "vpc-produccion"
  
  # Usar todas las AZs disponibles para HA
  azs = data.aws_availability_zones.available.names
  
  # Configuración de subnets
  private_subnets         = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  database_subnets        = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  create_database_subnets = true
  
  # Configuración HA para NAT
  enable_nat_gateway = true
  single_nat_gateway = false  # Un NAT por AZ
  
  # Habilitar todo el monitoreo
  enable_flow_logs        = true
  flow_log_destination    = "s3"
  flow_log_s3_bucket     = "mi-bucket-flow-logs"
  
  project_tags = {
    Environment = "produccion"
    Criticality = "alta"
    Compliance  = "pci-dss"
  }
}
```

## 👨‍💻 Autor

**Hermes Vargas**  
📧 Email: hermesvargas200720@gmail.com  
🔗 GitHub: [@hvargas2007](https://github.com/hvargas2007)

## 📊 Estadísticas del Módulo

![Versión](https://img.shields.io/github/v/release/hvargas2007/vpc-workflow-terraform)
![Descargas](https://img.shields.io/github/downloads/hvargas2007/vpc-workflow-terraform/total)
![Issues](https://img.shields.io/github/issues/hvargas2007/vpc-workflow-terraform)
![Pull Requests](https://img.shields.io/github/issues-pr/hvargas2007/vpc-workflow-terraform)

---

Hecho con ❤️ para toda la comunidad