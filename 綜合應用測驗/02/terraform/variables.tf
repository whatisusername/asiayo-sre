variable "region" {
  description = "Provision in which AWS region."
  type        = string
  default     = "ap-east-2"
}

################################################################################
# VPC
################################################################################

variable "vpc_cidr" {
  type        = string
  description = "The IPv4 CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "az_number" {
  type        = number
  description = "The number of availability zones to use."
  default     = 3

  validation {
    condition     = var.az_number >= 1
    error_message = "The number of availability zones should be at least 1."
  }
}

variable "public_subnet_number" {
  type        = number
  description = "The number of public subnets."
  default     = 3

  validation {
    condition     = var.public_subnet_number % var.az_number == 0
    error_message = "The number of public subnets should be a multiple of az_number."
  }
}

variable "private_subnet_number" {
  type        = number
  description = "The number of private subnets."
  default     = 3

  validation {
    condition     = var.private_subnet_number % var.az_number == 0
    error_message = "The number of private subnets should be a multiple of az_number."
  }
}

################################################################################
# EKS
################################################################################

variable "endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
