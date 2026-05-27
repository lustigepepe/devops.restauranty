variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "hagen-restauranty-rg"
}

variable "location" {
  description = "Azure region to deploy into"
  type        = string
  default     = "centralus"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "restauranty-aks"
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
  default     = "production"
}
