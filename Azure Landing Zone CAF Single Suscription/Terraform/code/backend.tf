terraform {
  backend "azurerm" {
    resource_group_name  = "RG-Terraform-State"
    storage_account_name = "dctstateterraform"
    container_name       = "tfstate"
    key                  = "alz-single-subscription.tfstate"
  }
}