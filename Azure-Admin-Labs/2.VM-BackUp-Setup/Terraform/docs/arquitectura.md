Azure-RSV-VM-Setup  
0.	Objetivo  
En este laboratorio crearemos a través de Terraform la infraestructura necesaria para realizar una recuperación de discos a través de varios metódos de recuperación.  
El objetivo es la creación de todo este entorno desde 0, identificando y seleccionando los recursos necesarios para ello en registry.terraform /azurerm.
Una vez finalizado, se hará un checklist de la infraestructura desplegada.


Índice
0.	Objetivo
1.	Providers.tf
2.	Main.tf
resource "azurerm_resource_group" "rg" {
resource "azurerm_virtual_network" "vnet" {
resource "azurerm_subnet" "snet" {
resource "azurerm_public_ip" "pip" {
resource "azurerm_network_interface" "nic" {
resource "azurerm_network_security_group" "nsg" {	
resource "azurerm_subnet_network_security_group_association" "assoc" {
resource "azurerm_windows_virtual_machine" "vm" {
resource "azurerm_recovery_services_vault" "vault" {
resource "azurerm_backup_policy_vm" "policy" {
resource "azurerm_backup_protected_vm" "vm1" {
resource "azurerm_storage_account" "storage" {
3.	Variables.tf	7
4.	Terraform.tfvars	9


1.	Providers.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.76.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}


2.	Main.tf
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = [var.vnet_add]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "snet" {
  name                 = var.snet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snet_add]
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.privip
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.snet_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-rdp-myip"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.myip
    destination_address_prefix = var.privip

  }
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = azurerm_subnet.snet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_recovery_services_vault" "vault" {
  name                = var.vault_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  storage_mode_type = "LocallyRedundant"
}

resource "azurerm_backup_policy_vm" "policy" {
  name                = "${var.vault_name}-policy"
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 7
  }
}

resource "azurerm_backup_protected_vm" "vm1" {
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  source_vm_id        = azurerm_windows_virtual_machine.vm.id
  backup_policy_id    = azurerm_backup_policy_vm.policy.id
}

resource "azurerm_storage_account" "storage" {
  name                     = var.storage_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


3.	Variables.tf
variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "location" {
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

variable "vm_name" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "vault_name" {
    type = string
}

variable "storage_name" {
    type = string
}


4.	Terraform.tfvars
#Main values
subscription_id = "X"
tenant_id       = "X"

#Rg values
rg_name  = "rg-security-lab"
location = "spaincentral"

#Network values
vnet_name = "vm01-vnet"
vnet_add  = "10.0.0.0/24"

snet_name = "vm01-snet"
snet_add  = "10.0.0.0/26"

myip = “”
miprivip = “10.0.0.4”

#Compute values
vm_name  = "vm01"
admin_username = "DaniCloudTech"
admin_password = "SuperSecret123!"

#RSV values
vault_name = "vault-rsv-lab"

#Storage value
storage_name = "danicloudtS