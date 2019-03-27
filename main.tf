
resource "azurerm_availability_set" "main-aset" {
  name                         = "${var.prefix}-${var.env}-avset"
  location                     = "${var.region}"
  resource_group_name          = "${azurerm_resource_group.rsg.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 10
  managed                      = true
}

resource "azurerm_resource_group" "rsg" {
  name     = "${var.prefix}-${var.env}-rsg"
  location = "${var.region}"

  tags = {
    environment = "${var.env}"
  }
}
resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.prefix}-vm${count.index}-${var.env}"
  location              = "${azurerm_resource_group.rsg.location}"
  resource_group_name   = "${azurerm_resource_group.rsg.name}"
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  availability_set_id   = "${azurerm_availability_set.main-aset.id}"
  vm_size               = "${var.env=="dev" ? "Standard_A0" : "Standard_DS1_v2"}"
  
  count = "${var.vms_count}"
   
 storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
 storage_os_disk {
    name              = "${var.prefix}-vm${count.index}-${var.env}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
 
   os_profile {
    computer_name  = "${var.prefix}-vm${count.index}-${var.env}"
    admin_username = "${var.username}"
    admin_password = "${var.password}"

  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
    

  tags = {
    environment = "${var.env}"
    ssh = "${data.azurerm_public_ip.lb-ip.ip_address}:2200${count.index}"
  }
   
   connection {
      host = "${azurerm_public_ip.lbpip.ip_address}"
      port = "2200${count.index}"
      type = "ssh"
      user = "${var.username}"
      password = "${var.password}"
   }
   provisioner "file" {
    source      = "files/webdeploy.sh"
    destination = "/tmp/webdeploy.sh"
  }

  provisioner "remote-exec" {
    inline = [

      
      "sudo chmod a+x /tmp/webdeploy.sh",
      "sh /tmp/webdeploy.sh > /dev/null 2>&1 ",
      "sleep 1",
    ]
  }
  

 //depends_on = ["azurerm_network_interface."]

  #depends_on = ["azurerm_virtual_machine_extension.test"]
}


resource "azurerm_lb" "web-lb" {
  resource_group_name = "${azurerm_resource_group.rsg.name}"
  name                = "${var.prefix}-${var.env}-lb"
  location            = "${var.region}"
  //sku                 = "Standard"


  frontend_ip_configuration {
    name                 = "LBFrontEnd"
    public_ip_address_id = "${azurerm_public_ip.lbpip.id}"
  }
}
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  resource_group_name = "${azurerm_resource_group.rsg.name}"
  loadbalancer_id     = "${azurerm_lb.web-lb.id}"
  name                = "${var.prefix}-BackendPool-${var.env}"
}

resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name = "${azurerm_resource_group.rsg.name}"
  loadbalancer_id     = "${azurerm_lb.web-lb.id}"
  name                = "tcpProbe-${var.env}"
  protocol            = "tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "lb_rule" {
  resource_group_name            = "${azurerm_resource_group.rsg.name}"
  loadbalancer_id                = "${azurerm_lb.web-lb.id}"
  name                           = "webBalanceRule-${var.env}"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 80
  //frontend_ip_configuration_name = "${azurerm_lb.main-lb.frontend_ip_configuration_name}"
  frontend_ip_configuration_name = "LBFrontEnd"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.backend_pool.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.lb_probe.id}"
  depends_on                     = ["azurerm_lb_probe.lb_probe"]
}

/*resource "azurerm_lb_outbound_rule" "out-nat" {
  resource_group_name = "${azurerm_resource_group.rsg.name}"
  loadbalancer_id = "${azurerm_lb.web-lb.id}"
  name = "outboundRule"
  frontend_ip_configurations  {
     name = "PublicIPAddress"
     }
  idleTimeoutInMinutes = 60
  protocol = "All"
  backendAddressPool = "${azurerm_lb_backend_address_pool.backend_pool.id}"
}
*/
resource "azurerm_lb_nat_rule" "vm-ssh" {
  resource_group_name            = "${azurerm_resource_group.rsg.name}"
  loadbalancer_id                = "${azurerm_lb.web-lb.id}"
  name                           = "SSH-VM-${count.index}-${var.env}"
  protocol                       = "tcp"
  frontend_port                  = "2200${count.index}"
  backend_port                   = 22
  frontend_ip_configuration_name = "LBFrontEnd"
  
  //frontend_ip_configuration_name = "${azurerm_lb.main-lb.frontend_ip_configuration_name}"
  count                          = "${var.vms_count}"
}


