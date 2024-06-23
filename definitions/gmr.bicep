targetScope = 'subscription'

param network_rg_config object
param vnet_config object
param vhub_link_config object
param network_auxiliary_config object
param hub_fw_config object
param databricks_nsg_config object

param databricks_udr_config object

// REFERENCE EXISTING RESOURCES
resource hub_fw 'Microsoft.Network/azureFirewalls@2020-11-01' existing = {
  name: hub_fw_config.name
  scope: resourceGroup(hub_fw_config.subId, hub_fw_config.rgName)
}
// use this format 'name: ${identity_vnet_config.name}-${uniqueString(deployment().name, guid(subscription().id, identity_vnet_config.name))}' instead of ' name: uniqueString(deployment().name, guid(subscription().id, identity_rg_config.name))' to avoid ambiguius deployment names 
// -- network resource group and associated resources
module network_rg '../modules/resources/resource-group/main.bicep' = {
  name: '${network_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, network_rg_config.name))}'
  scope: subscription(network_rg_config.targetSubscriptionId)
  params: {
    name: network_rg_config.name
    tags: network_rg_config.tags
  }
}



module vnet '../customModules/virtual-network/main.bicep' = {
  name:'${vnet_config.name}-${uniqueString(deployment().name, guid(subscription().id, vnet_config.name))}'
  scope: resourceGroup(network_rg_config.targetSubscriptionId, network_rg_config.name)
  dependsOn: [network_rg, network_auxiliary_rg, databricks_nsg, databricks_udr]
  params: {
    addressPrefixes: [vnet_config.addressSpace]
    name: vnet_config.name
    flowTimeoutInMinutes: vnet_config.flowTimeoutInMinutes
    subnets: vnet_config.subnetConfigs
    tags: vnet_config.tags
    dnsServers: [hub_fw.properties.hubIPAddresses.privateIPAddress]
  }
}




module vhub_link '../modules/network/virtual-hub/hub-virtual-network-connection/main.bicep' = {
  name: '${vhub_link_config.name}-${uniqueString(deployment().name, guid(subscription().id, vhub_link_config.name))}'
  scope: resourceGroup(vhub_link_config.targetVhub.subId, vhub_link_config.targetVhub.rg)
  dependsOn: [vnet]
  params: {
    name: vhub_link_config.name
    virtualHubName: vhub_link_config.targetVhub.name
    remoteVirtualNetworkId: vnet.outputs.resourceId
    routingConfiguration: vhub_link_config.routingConfiguration
  }
}

module network_auxiliary_rg '../modules/resources/resource-group/main.bicep' = {
  name: '${network_auxiliary_config.name}-${uniqueString(deployment().name, guid(subscription().id, network_auxiliary_config.name))}'
  scope: subscription(network_auxiliary_config.targetSubscriptionId)
  params: {
    name: network_auxiliary_config.name
    tags: network_auxiliary_config.tags
  }
}

module databricks_nsg '../modules/network/network-security-group/main.bicep' = {
  name:'${databricks_nsg_config.name}-${uniqueString(deployment().name, guid(subscription().id, databricks_nsg_config.name))}'
  scope: resourceGroup(network_auxiliary_config.targetSubscriptionId, network_auxiliary_config.name)
  dependsOn: [network_auxiliary_rg]
  params: {
    name: databricks_nsg_config.name
    securityRules: databricks_nsg_config.securityRules
    tags: databricks_nsg_config.tags
  }
}


module databricks_udr '../modules/network/route-table/main.bicep' = {
  name:'${databricks_udr_config.name}-${uniqueString(deployment().name, guid(subscription().id, databricks_udr_config.name))}'
  scope: resourceGroup(network_auxiliary_config.targetSubscriptionId, network_auxiliary_config.name)
  dependsOn: [network_auxiliary_rg]
  params: {
    name: databricks_udr_config.name
    routes: databricks_udr_config.routes
    tags: databricks_udr_config.tags
  }
}
