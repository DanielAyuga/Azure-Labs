#Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.law_name
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "time_sleep" "wait_for_law" {
  depends_on = [azurerm_log_analytics_workspace.law]
  create_duration = "30s"
}

resource "time_sleep" "wait_for_ama" {
  depends_on = [
    var.ama_extension_id
  ]
  create_duration = "45s"
}

#Data Rule Collection (DCR)
resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = var.dcr_name
  location            = var.location
  resource_group_name = var.rg_name

  depends_on = [
    azurerm_log_analytics_workspace.law,
    time_sleep.wait_for_law,
    time_sleep.wait_for_ama
  ]

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
      name                  = "lawdest"
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf", "Microsoft-Event", "Microsoft-Heartbeat"]
    destinations = ["lawdest"]
  }

  data_sources {

    windows_event_log {
      name    = "eventLogs"
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "Application!*[System[(Level=1 or Level=2)]]",
        "System!*[System[(Level=1 or Level=2)]]",
        "Security!*[System[(EventID=4625 or EventID=4624)]]"
      ]
    }

    performance_counter {
      name        = "perfCounters"
      streams     = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor Information(_Total)\\% Processor Time",
        "\\Memory\\Available Bytes",
        "\\LogicalDisk(_Total)\\% Free Space"
      ]
    }
  }
}

# Workbook
resource "azurerm_application_insights_workbook" "vm_workbook" {
  name                = uuid()
  resource_group_name = var.rg_name
  location            = var.location
  display_name        = var.vm_workbook_name
  category            = "workbook"

  data_json = templatefile("${path.module}/workbook.json", {
    law_id = azurerm_log_analytics_workspace.law.id
  })
}

# Action Group
resource "azurerm_monitor_action_group" "ag" {
  name                = var.action_group_name
  resource_group_name = var.rg_name
  short_name          = "alerts"

  email_receiver {
    name                    = "emailReceiver"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

# CPU Alert
resource "azurerm_monitor_metric_alert" "cpu_high" {
  name                = "${var.vm_name}-cpu-high"
  resource_group_name = var.rg_name
  scopes              = [var.vm_id]
  description         = "CPU usage above 80%"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
}

# Failed Logins Alert
resource "azurerm_monitor_scheduled_query_rules_alert" "failed_logins" {
  name                = "${var.vm_name}-failed-logins"
  resource_group_name = var.rg_name
  location            = var.location
  description         = "Detects 5 failed login attempts in 5 minutes"
  severity            = 2
  enabled             = true

  depends_on = [
  azurerm_monitor_data_collection_rule.dcr,
  time_sleep.wait_for_law
]

  frequency   = 5
  time_window = 5

  query = <<-EOF
  Event
  | where TimeGenerated > ago(5m)
  | where EventID == 4625
  | summarize fails = count() by Computer
  | where fails >= 5
  EOF

  data_source_id = azurerm_log_analytics_workspace.law.id

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  action {
    action_group = [azurerm_monitor_action_group.ag.id]
  }
}

# Heartbeat Alert
resource "azurerm_monitor_scheduled_query_rules_alert" "vm_powerstate" {
  name                = "${var.vm_name}-powerstate"
  resource_group_name = var.rg_name
  location            = var.location
  description         = "Detects if the VM stops sending Heartbeat"
  severity            = 2
  enabled             = true

  depends_on = [
  azurerm_monitor_data_collection_rule.dcr,
  time_sleep.wait_for_law
]

  frequency   = 5
  time_window = 5

  query = <<-EOF
  Heartbeat
  | summarize LastSeen = max(TimeGenerated)
  | extend MinutesSince = datetime_diff('minute', now(), LastSeen)
  | where MinutesSince > 5
  EOF

  data_source_id = azurerm_log_analytics_workspace.law.id

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  action {
    action_group = [azurerm_monitor_action_group.ag.id]
  }
}
