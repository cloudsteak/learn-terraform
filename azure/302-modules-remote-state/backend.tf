terraform {
  backend "azurerm" {
    resource_group_name  = "rg-learn-terraform-state"
    storage_account_name = "terraform000000000"
    container_name       = "tfstate"
    key                  = "302-modules-remote-state.tfstate"
  }
}
