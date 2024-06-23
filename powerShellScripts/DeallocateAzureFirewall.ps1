param (
    [string]$subscriptionId,
    [string]$iac_env,
    [string]$location_suffix
)

if ([string]::IsNullOrEmpty($subscriptionId)) {
    throw "Subscription ID is not set."
}

# Set the subscription context
Select-AzSubscription -SubscriptionId $subscriptionId

# Variables
$scope_prefix = "platform"
$iac_env_lower = $iac_env.ToLower()
$fwName = "$scope_prefix-fw-$iac_env_lower-$location_suffix"
$rgName = "$scope_prefix-network-rg-$iac_env_lower-$location_suffix"

# Deallocate Azure Firewall
$azfw = Get-AzFirewall -Name $fwName -ResourceGroupName $rgName
if ($azfw) {
    $azfw.Deallocate()
    Set-AzFirewall -AzureFirewall $azfw
    Write-Output "Deallocated Azure Firewall $fwName in resource group $rgName"
} else {
    Write-Output "Firewall $fwName not found in resource group $rgName"
}
