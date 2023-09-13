provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "test-resources"
  location = "West Europe"
}

module "network-security-group" {
  source                = "Azure/network-security-group/azurerm"
  resource_group_name   = azurerm_resource_group.example.name
  location              = "EastUS"
  security_group_name   = "nsg"
  source_address_prefix = ["10.0.3.0/24"]
  predefined_rules = [
    {
      name     = "SSH"
      priority = "500"
    },
    {
      name              = "LDAP"
      source_port_range = "1024-1026"
    }
  ]

  custom_rules = [
    {
      name                   = "myssh"
      priority               = 201
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      source_port_range      = "*"
      destination_port_range = "22"
      source_address_prefix  = "10.151.0.0/24"
      description            = "description-myssh"
    },
    {
      name                    = "myhttp"
      priority                = 200
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_port_range       = "*"
      destination_port_range  = "8080"
      source_address_prefixes = ["10.151.0.0/24", "10.151.1.0/24"]
      description             = "description-http"
    },
  ]

  tags = {
    environment = "dev"
    costcenter  = "it"
  }

  depends_on = [azurerm_resource_group.example]
}

module "vnet" {
  source              = "Azure/vnet/azurerm"
  use_for_each        = "false"
  version             = "4.1.0"
  vnet_name           = "myvnet"
  vnet_location       = "West Europe"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.example.name
  subnet_names        = ["subnet1", "subnet2"]
  subnet_prefixes     = ["10.0.1.0/16", "10.0.2.0/16"]
  nsg_ids = {
    "subnet1" = module.network-security-group.network_security_group_id,
    "subnet2" = module.network-security-group.network_security_group_id
  }
  tags = {
    environment = "dev"
    costcenter  = "it"
  }
}