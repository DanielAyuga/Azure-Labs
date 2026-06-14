# Espera para que Azure termine de propagar el Log Analytics Workspace
resource "time_sleep" "wait_for_law" {
  depends_on      = [module.monitoring]
  create_duration = "120s"

  triggers = {
    law_id = lower(module.monitoring.law_id)
  }
}

# Workbook
resource "azurerm_application_insights_workbook" "vm_workbook" {
  name                = uuid()
  resource_group_name = var.rg_name
  location            = var.location
  display_name        = var.vm_workbook_name
  category            = "workbook"

  source_id = lower(module.monitoring.law_id)

  data_json = templatefile("${path.module}/modules/monitoring/workbook.json", {
    law_id = lower(module.monitoring.law_id)
  })

  depends_on = [
    time_sleep.wait_for_law
  ]
}
