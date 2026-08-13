###############################################
# MANAGEMENT GROUP POLICIES (MG LEVEL)
###############################################

# 1. Allowed Locations
resource "azapi_resource" "allowed_locations" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "allowed-locations"
  parent_id = "/providers/Microsoft.Management/managementGroups/0cbe8bb3-380e-4fd0-9872-05d29a282166"

  body = jsonencode({
    properties = {
      displayName        = "Allowed Locations - DaniCloudTech"
      policyDefinitionId = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"

      parameters = {
        listOfAllowedLocations = {
          value = [
            "Spain Central",
            "France Central",
            "East US"
          ]
        }

        # Recomendable especificarlo explícitamente
        effect = {
          value = "Deny"
        }
      }

      enforcementMode = "Default"
    }
  })
}

# 2. Key Vault Purge Protection
resource "azapi_resource" "kv_purge_protection" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "kv-purge-protection"
  parent_id = "/providers/Microsoft.Management/managementGroups/0cbe8bb3-380e-4fd0-9872-05d29a282166"

  body = jsonencode({
    properties = {
      displayName        = "Key Vault Purge Protection Required"
      policyDefinitionId = "/providers/Microsoft.Authorization/policyDefinitions/0b60c0b2-2dc2-4e1c-b5c9-abbed971de53"
    }
  })
}

# 3. Key Vault Soft Delete
resource "azapi_resource" "kv_soft_delete" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "kv-soft-delete"
  parent_id = "/providers/Microsoft.Management/managementGroups/0cbe8bb3-380e-4fd0-9872-05d29a282166"

  body = jsonencode({
    properties = {
      displayName        = "Key Vault Soft Delete Required"
      policyDefinitionId = "/providers/Microsoft.Authorization/policyDefinitions/1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d"
    }
  })
}

# 4. Key Vault RBAC Required
resource "azapi_resource" "kv_rbac" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "kv-rbac-required"
  parent_id = "/providers/Microsoft.Management/managementGroups/0cbe8bb3-380e-4fd0-9872-05d29a282166"

  body = jsonencode({
    properties = {
      displayName        = "Key Vault RBAC Authorization Required"
      policyDefinitionId = "/providers/Microsoft.Authorization/policyDefinitions/12d4fa5e-1f9f-4c21-97a9-b99b3c6611b5"
    }
  })
}

# 5. Diagnostic Settings → LAW
resource "azapi_resource" "diagnostic_settings_recovery_services" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "diag-rsv-law"
  parent_id = "/providers/Microsoft.Management/managementGroups/0cbe8bb3-380e-4fd0-9872-05d29a282166"

  location = var.location

  identity {
    type = "SystemAssigned"
  }

  body = jsonencode({
    properties = {
      displayName = "Deploy Diagnostic Settings - Recovery Services Vault - LAW"

      policyDefinitionId = "/providers/Microsoft.Authorization/policyDefinitions/c717fb0c-d118-4c43-ab3d-ece30ac81fb3"

      parameters = {
        logAnalytics = {
          value = var.law_id
        }

        profileName = {
          value = "setbypolicy_logAnalytics"
        }

        tagName = {
          value = ""
        }

        tagValue = {
          value = ""
        }
      }
    }
  })
}

resource "azapi_resource" "diagnostic_settings_key_vault" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "diag-keyvault-law"
  parent_id = "/providers/Microsoft.Management/managementGroups/0cbe8bb3-380e-4fd0-9872-05d29a282166"

  location = var.location

  identity {
    type = "SystemAssigned"
  }

  body = jsonencode({
    properties = {
      displayName = "Deploy Diagnostic Settings - Key Vault - LAW"

      policyDefinitionId = "/providers/Microsoft.Authorization/policyDefinitions/bef3f64c-5290-43b7-85b0-9b254eef4c47"

      parameters = {
        effect = {
          value = "DeployIfNotExists"
        }

        profileName = {
          value = "setbypolicy_logAnalytics"
        }

        logAnalytics = {
          value = var.law_id
        }

        metricsEnabled = {
          value = "False"
        }

        logsEnabled = {
          value = "True"
        }

        matchWorkspace = {
          value = true
        }
      }
    }
  })
}

# 6. Allowed VM Sizes
resource "azapi_resource" "allowed_vm_sizes" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "allowed-vm-sizes"
  parent_id = "/providers/Microsoft.Management/managementGroups/0cbe8bb3-380e-4fd0-9872-05d29a282166"

  body = jsonencode({
    properties = {
      displayName        = "Allowed VM Sizes - DaniCloudTech"
      policyDefinitionId = "/providers/Microsoft.Authorization/policyDefinitions/cccc23c7-8427-4f53-ad12-b6a63eb452b3"

      parameters = {
        listOfAllowedSKUs = {
          value = [
            "Standard_B1s",
            "Standard_B2s",
            "Standard_B2ms",
            "Standard_D2s_v3",
            "Standard_D4s_v3"
          ]
        }
      }
    }
  })
}

# 7. Storage HTTPS Only
resource "azapi_resource" "storage_https_only" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "storage-https-only"
  parent_id = "/providers/Microsoft.Management/managementGroups/0cbe8bb3-380e-4fd0-9872-05d29a282166"

  body = jsonencode({
    properties = {
      displayName        = "Storage Accounts Must Enforce HTTPS"
      policyDefinitionId = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"

      parameters = {
        effect = {
          value = "Audit"
        }
      }

      enforcementMode = "Default"
    }
  })
}

###############################################
# RESOURCE GROUP POLICIES (RG LEVEL)
###############################################

locals {
  append_tag_definition = "/providers/Microsoft.Authorization/policyDefinitions/2a0e14a6-b0a6-4fab-991a-187a4f81c498"
}

# RG Identity
resource "azapi_resource" "rg_identity_append_tag" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "append-tag-identity"
  parent_id = var.resource_group_ids["identity"]

  body = jsonencode({
    properties = {
      displayName        = "Append environment=identity"
      policyDefinitionId = local.append_tag_definition

      parameters = {
        tagName = {
          value = "environment"
        }

        tagValue = {
          value = "identity"
        }
      }
    }
  })
}

# RG Networking
resource "azapi_resource" "rg_networking_append_tag" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "append-tag-networking"
  parent_id = var.resource_group_ids["networking"]

  body = jsonencode({
    properties = {
      displayName        = "Append environment=networking"
      policyDefinitionId = local.append_tag_definition
      parameters = {
        tagName  = { value = "environment" }
        tagValue = { value = "networking" }
      }
    }
  })
}

# Subnets must have NSG
resource "azapi_resource" "rg_networking_subnets_nsg" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "subnets-must-have-nsg"
  parent_id = var.resource_group_ids["networking"]

  body = jsonencode({
    properties = {
      displayName        = "Subnets must have NSG"
      policyDefinitionId = "/providers/Microsoft.Authorization/policyDefinitions/e71308d3-144b-4262-b144-efdc3cc90517"

      parameters = {
        effect = {
          value = "AuditIfNotExists"
        }
      }
    }
  })
}

# RG Monitoring
resource "azapi_resource" "rg_monitoring_append_tag" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "append-tag-monitoring"
  parent_id = var.resource_group_ids["monitoring"]

  body = jsonencode({
    properties = {
      displayName        = "Append environment=monitoring"
      policyDefinitionId = local.append_tag_definition
      parameters = {
        tagName  = { value = "environment" }
        tagValue = { value = "monitoring" }
      }
    }
  })
}

# RG Security
resource "azapi_resource" "rg_security_append_tag" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "append-tag-security"
  parent_id = var.resource_group_ids["security"]

  body = jsonencode({
    properties = {
      displayName        = "Append environment=security"
      policyDefinitionId = local.append_tag_definition
      parameters = {
        tagName  = { value = "environment" }
        tagValue = { value = "security" }
      }
    }
  })
}

# RG Dev
resource "azapi_resource" "rg_dev_append_tag" {
  type      = "Microsoft.Authorization/policyAssignments@2021-06-01"
  name      = "append-tag-dev"
  parent_id = var.resource_group_ids["dev"]

  body = jsonencode({
    properties = {
      displayName        = "Append environment=dev"
      policyDefinitionId = local.append_tag_definition
      parameters = {
        tagName  = { value = "environment" }
        tagValue = { value = "dev" }
      }
    }
  })
}
