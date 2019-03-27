
data "azurerm_public_ip" "lb-ip" {
  name                = "${azurerm_public_ip.lbpip.name}"
  resource_group_name = "${azurerm_resource_group.rsg.name}"
}

output "public_ip_address_lb" {
  value = "${data.azurerm_public_ip.lb-ip.ip_address}"
}


output "vms_ssh_port" {
  value = "${azurerm_virtual_machine.vm.*.tags}"

}

/* "azurerm_public_ip" "main-data-ip" {
  count               = "${var.vms_count}"

  name                = "${element(azurerm_public_ip.main-ip.*.name, count.index)}"
  resource_group_name = "${azurerm_resource_group.rsg.name}"
}

output "public_ip_address_vm" {
  value = "${data.azurerm_public_ip.main-data-ip.ip_address}"
}
*/

