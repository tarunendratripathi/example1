resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_public_ip" "nat_ip" {
  name                = "nat-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_nat_gateway" "nat" {
  name                = "nat-gateway"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_ip.id

  depends_on = [azurerm_nat_gateway.nat, azurerm_public_ip.nat_ip]
}

resource "azurerm_subnet" "subnets" {
  for_each             = { for subnet in var.subnets : subnet.name => subnet }
  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [each.value.address_prefix]

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_subnet_nat_gateway_association" "nat_assoc" {
  for_each       = { for subnet in var.subnets : subnet.name => subnet if subnet.type == "private" }
  subnet_id      = azurerm_subnet.subnets[each.key].id
  nat_gateway_id = azurerm_nat_gateway.nat.id

  depends_on = [azurerm_subnet.subnets, azurerm_nat_gateway.nat]
}

resource "azurerm_network_security_group" "nsg" {
  for_each            = { for subnet in var.subnets : subnet.name => subnet }
  name                = "${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  depends_on = [azurerm_resource_group.rg]

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = azurerm_subnet.subnets
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id

  depends_on = [azurerm_subnet.subnets, azurerm_network_security_group.nsg]
}

resource "azurerm_route_table" "rt" {
  for_each            = azurerm_subnet.subnets
  name                = "${each.key}-rt"
  location            = var.location
  resource_group_name = var.resource_group_name

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_subnet_route_table_association" "rt_assoc" {
  for_each       = azurerm_subnet.subnets
  subnet_id      = each.value.id
  route_table_id = azurerm_route_table.rt[each.key].id

  depends_on = [azurerm_subnet.subnets, azurerm_route_table.rt]
}