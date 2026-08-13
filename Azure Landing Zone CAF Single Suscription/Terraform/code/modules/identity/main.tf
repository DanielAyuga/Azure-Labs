resource "azurerm_role_assignment" "platform_admin_contributor" {
  principal_id         = var.grp_platform_admin_id
  role_definition_name = "Contributor"
  scope                = "/subscriptions/${var.subscription_id}"
}

