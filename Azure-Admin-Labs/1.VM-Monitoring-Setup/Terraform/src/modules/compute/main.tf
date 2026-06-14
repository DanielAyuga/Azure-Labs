resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = var.rg_name
  location            = var.location
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

    identity {
    type = "SystemAssigned"
  }

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
    sku       = "2022-datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "wait_for_boot" {
  name                       = "${var.vm_name}-wait"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell.exe -Command \"Start-Sleep -Seconds 180\""
    }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "${var.vm_name}-ama"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.10"
  automatic_upgrade_enabled  = false

  settings = jsonencode({})

  depends_on = [
    azurerm_virtual_machine_extension.wait_for_boot
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "dcr_assoc" {
  name                    = "${var.vm_name}-dcr-assoc"
  target_resource_id      = azurerm_windows_virtual_machine.vm.id
  data_collection_rule_id = var.dcr_id

  depends_on = [
    azurerm_virtual_machine_extension.ama
  ]
}

resource "azurerm_network_interface" "nic" {
  name                = var.nic_name
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = var.nsg_id
}

