param (
    [string]$subscriptionId,
    [string]$iac_env,
    [string]$location_suffix
)

# Delete Site-to-Site VPN Gateway for non-main branch
Set-AzContext -SubscriptionId $subscriptionId
$resourceGroupName = "platform-network-rg-$iac_env-$location_suffix".ToLower()
$vpnGatewayName = "platform-s2s-gateway-$iac_env".ToLower() + "-$location_suffix"

try {
  $vpnGateway = Get-AzVpnGateway -ResourceGroupName $resourceGroupName -Name $vpnGatewayName
  if ($vpnGateway) {
    Remove-AzVpnGateway -ResourceGroupName $resourceGroupName -Name $vpnGatewayName -Force
    Write-Output "Deleted Site-to-Site VPN Gateway $vpnGatewayName in resource group $resourceGroupName"
  } else {
    Write-Output "Site-to-Site VPN Gateway $vpnGatewayName not found in resource group $resourceGroupName"
  }
} catch {
  Write-Output "Error deleting Site-to-Site VPN Gateway ${vpnGatewayName}: $($_.Exception.Message)"
}
