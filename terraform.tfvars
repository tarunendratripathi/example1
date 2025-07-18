resource_group_name = "example1"
location            = "East US"
vnet_name           = "example-vnet"
vnet_address_space  = ["10.0.0.0/16"]

subnets = [
  { name = "public-subnet-1",  address_prefix = "10.0.1.0/24",  type = "public" },
  { name = "public-subnet-2",  address_prefix = "10.0.2.0/24",  type = "public" },
  { name = "private-subnet-1", address_prefix = "10.0.3.0/24",  type = "private" },
  { name = "private-subnet-2", address_prefix = "10.0.4.0/24",  type = "private" }
]

nsg_rules = [
  {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
  {
    name                       = "AllowHTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
]