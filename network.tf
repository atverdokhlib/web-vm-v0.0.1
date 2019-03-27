#resource "azurerm_network_watcher" "test" {
# name                = "network-watcher"
#  location            = "${azurerm_resource_group.rsg-westeu.location}"
#  resource_group_name = "${azurerm_resource_group.rsg-westeu.name}"
#}
resource "azurerm_network_security_group" "mng-nsg" {
  name                = "${var.prefix}-nsg-${var.env}"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.rsg.name}"

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

   
}

resource "azurerm_virtual_network" "westeu-network" {
  name                = "${var.prefix}-network-${var.env}"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.rsg.location}"
  resource_group_name = "${azurerm_resource_group.rsg.name}"
   tags = {
     environment = "${var.env}"
  }
}
resource "azurerm_subnet" "lan-subnet" {
  name                 = "${var.prefix}-lan-${var.env}"
  resource_group_name  = "${azurerm_resource_group.rsg.name}"
  virtual_network_name = "${azurerm_virtual_network.westeu-network.name}"
  address_prefix       = "10.0.1.0/24"
  //network_security_group_id = "${azurerm_network_security_group.mng-nsg.id}"
  
   
   
}

resource "azurerm_subnet_network_security_group_association" "test" {
  subnet_id                 = "${azurerm_subnet.lan-subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.mng-nsg.id}"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic${count.index}-${var.env}"
  location            = "${azurerm_resource_group.rsg.location}"
  resource_group_name = "${azurerm_resource_group.rsg.name}"
  count               = "${var.vms_count}"
  ip_configuration {
    name                          = "terraform-test-nic-ip"
    subnet_id                     = "${azurerm_subnet.lan-subnet.id}"
    private_ip_address_allocation = "Dynamic"
   // public_ip_address_id          = "${element(azurerm_public_ip.main-ip.*.id, count.index)}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.backend_pool.id}"]
    load_balancer_inbound_nat_rules_ids    = ["${element(azurerm_lb_nat_rule.vm-ssh.*.id, count.index)}"]
  }
  
}


resource "azurerm_public_ip" "lbpip" {
  name                = "${var.prefix}-lb-pip-${var.env}"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.rsg.name}"
  allocation_method   = "Static"

  domain_name_label   = "${var.dnsforpubip}-lb"
}

resource "azurerm_public_ip" "main-ip" {
  count = "${var.vms_count}"

  name                = "${var.prefix}-pip${count.index}-${var.env}"
  location            = "${azurerm_resource_group.rsg.location}"
  resource_group_name = "${azurerm_resource_group.rsg.name}"
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.dnsforpubip}-${count.index}"

  tags = "${merge(
    local.common_tags,
    map(
      "custom-ip", "${var.prefix}-ip${count.index}-${var.env}"
    )
  )}"  
}





