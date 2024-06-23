param (
    [string]$subscriptionId,
    [string]$iac_env,
    [string]$location_suffix
)

# Delete Point-to-Site VPN Gateway for non-main branch
Set-AzContext -SubscriptionId $subscriptionId
$resourceGroupName = "platform-network-rg-${iac_env}-${location_suffix}".ToLower()
$p2sVpnGatewayName = "platform-p2svpn-${iac_env}".ToLower() + "-${location_suffix}"

try {
    $p2sVpnGateway = Get-AzP2sVpnGateway -ResourceGroupName $resourceGroupName -Name $p2sVpnGatewayName
    if ($p2sVpnGateway) {
        Remove-AzP2sVpnGateway -ResourceGroupName $resourceGroupName -Name $p2sVpnGatewayName -Force
        Write-Output "Deleted Point-to-Site VPN Gateway ${p2sVpnGatewayName} in resource group ${resourceGroupName}"
    } else {
        Write-Output "Point-to-Site VPN Gateway ${p2sVpnGatewayName} not found in resource group ${resourceGroupName}"
    }
} catch {
    Write-Output "Error deleting Point-to-Site VPN Gateway ${p2sVpnGatewayName}: $($_.Exception.Message)"
}
