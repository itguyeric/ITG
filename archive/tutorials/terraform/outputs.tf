# Output name and ip address
output "Container Name" {
  value = "${module.container.container_name}"
}

output "IP Address" {
  value = "${module.container.ip}"
}
