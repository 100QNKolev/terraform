terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

#Create random integer
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "ContactBookRG${random_integer.ri.result}"
  location = var.resource_group_location
}

resource "azurerm_service_plan" "contactBookSP" {
  name                = "contact-book-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_app_service_source_control" "contactBookSC" {
  app_id   = azurerm_linux_web_app.contactBookWebApp.id //MAYBE NOT WORKING
  repo_url = var.source_control_git_url
  branch   = "main"
  use_manual_integration = true
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_mssql_server" "contactBookServer" {
  name                         = "contact-book-${random_integer.ri.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.server_admin_username
  administrator_login_password = var.server_admin_password
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_database" "ContactBookDB" {
  name           = var.database_name
  server_id      = azurerm_mssql_server.contactBookServer.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  sku_name       = "P1"
  zone_redundant = true
}

resource "azurerm_mssql_firewall_rule" "contactBookFR" {
  name             = var.firewall_name
  server_id        = azurerm_mssql_server.contactBookServer.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_linux_web_app" "contactBookWebApp" {
  name                = "contact-book-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.contactBookSP.id  //MAYBE NOT WORKING

  connection_string {
    name = "DefaultConnection"
    type = "SQLAzure"
    value = "Data Source=tcp:contact-book-75210.database.windows.net,1433;Initial Catalog=${azurerm_mssql_database.ContactBookDB.name};User ID=${azurerm_mssql_server.contactBookServer.administrator_login};Password=${azurerm_mssql_server.contactBookServer.administrator_login_password};Trusted_Connection=False; MultipleActiveResultSets=True;" 
  }

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }
}