module "management_group" {
  source           = "./modules/management_group"
  subscription_id  = var.subscription_id
  mg_name          = var.mg_name
}

module "resource_group" {
  source          = "./modules/resource_group"
  resource_groups = var.resource_groups
  location        = var.location
}

module "identity" {
  source                         = "./modules/identity"
  subscription_id                = var.subscription_id
  client_id                      = var.client_id
  grp_platform_admin_id          = var.grp_platform_admin_id

  management_group_id            = module.management_group.management_group_id
}

module "networking" {
  source                         = "./modules/networking"
  location              = var.location
  vnet_hub_name         = var.vnet_hub_name
  vnet_hub_address      = var.vnet_hub_address
  snet_bastion_name     = var.snet_bastion_name
  snet_bastion_address  = var.snet_bastion_address
  nsg_snet_bastion_name = var.nsg_snet_bastion_name

  resource_group_name   = module.resource_group.resource_group_names["networking"]
}

module "monitoring" {
  source                         = "./modules/monitoring"
  location                       = var.location
  law_name                       = var.law_name

  resource_group_name   = module.resource_group.resource_group_names["monitoring"]
}

module "security" {
  source                         = "./modules/security"
  tenant_id                      = var.tenant_id
  location                       = var.location
  kv_name                        = var.kv_name

  resource_group_name   = module.resource_group.resource_group_names["security"]
}

module "policies" {
  source            = "./modules/policies"
  mg_name           = var.mg_name
  subscription_id   = var.subscription_id
  location          = var.location

  resource_group_ids = module.resource_group.resource_group_ids  
  law_id             = module.monitoring.law_id
}
