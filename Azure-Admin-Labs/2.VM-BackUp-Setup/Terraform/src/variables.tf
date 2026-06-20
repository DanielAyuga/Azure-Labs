variable "subscription_id" {
    type = string
}

variable "tenant_id" {
    type = string
}

variable "rg_name" {
    type = string
}

variable "rg_location" {
    type = string
}

variable "vnet_name" {
    type = string
}

variable "vnet_add" {
    type = string
}

variable "snet_name" {
    type = string
}

variable "snet_add" {
    type = string
}

variable "nsg_name" {
    type = string
}

variable "myip" {
    type = string
}

variable "vm_name" {
    type = string
}

variable "adminuser" {
    type = string
}

variable "pass" {
    type = string
    sensitive = true
}

variable "vault_name" {
    type = string
}

variable "storage_name" {
    type = string
}

variable "privip" {
    type = string
}