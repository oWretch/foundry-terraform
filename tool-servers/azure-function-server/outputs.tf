output "function_app_name" { value = azurerm_linux_function_app.function.name }
output "function_app_hostname" { value = azurerm_linux_function_app.function.default_hostname }
output "function_private_endpoint_id" { value = azurerm_private_endpoint.main["function"].id }
output "function_app_resource_id" { value = azurerm_linux_function_app.function.id }