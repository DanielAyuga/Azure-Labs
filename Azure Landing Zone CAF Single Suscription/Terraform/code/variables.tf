variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}


#MG
variable "mg_name" {
  type = string
}

#RGs
variable "resource_groups" {
  type = map(string)
}

variable "location" {
  type = string
}


#Identity
variable "grp_platform_admin_id" {
  type = string
}


#Networking
variable "vnet_hub_name" {
  type = string
}

variable "vnet_hub_address" {
  type = string
}

variable "snet_bastion_name" {
  type = string
}

variable "snet_bastion_address" {
  type = string
}

variable "nsg_snet_bastion_name" {
  type = string
}


#Monitoring
variable "law_name" {
  type = string
}


#Security
variable "kv_name" {
  type = string
}
