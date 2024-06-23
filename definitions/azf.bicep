targetScope = 'subscription'

param network_rg_config object
param vnet_config object
param vhub_link_config object
param network_auxiliary_config object
param hub_fw_config object
param business_apps_rg_config object

// REFERENCE EXISTING RESOURCES
resource hub_fw 'Microsoft.Network/azureFirewalls@2020-11-01' existing = {
  name: hub_fw_config.name
  scope: resourceGroup(hub_fw_config.subId, hub_fw_config.rgName)
}

// use this format 'name: ${identity_vnet_config.name}-${uniqueString(deployment().name, guid(subscription().id, identity_vnet_config.name))}' instead of ' name: uniqueString(deployment().name, guid(subscription().id, identity_rg_config.name))' to avoid ambiguius deployment names 
// -- network resource group and associated resources
module network_rg '../modules/resources/resource-group/main.bicep' = {
  name:'${network_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, network_rg_config.name))}'
  scope: subscription(network_rg_config.targetSubscriptionId)
  params: {
    name: network_rg_config.name
    tags: network_rg_config.tags
  }
}



module vnet '../customModules/virtual-network/main.bicep' = {
  name:'${vnet_config.name}-${uniqueString(deployment().name, guid(subscription().id, vnet_config.name))}'
  scope: resourceGroup(network_rg_config.targetSubscriptionId, network_rg_config.name)
  dependsOn: [network_rg, network_auxiliary_rg]
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
  name:'${network_auxiliary_config.name}-${uniqueString(deployment().name, guid(subscription().id, network_auxiliary_config.name))}'
  scope: subscription(network_auxiliary_config.targetSubscriptionId)
  params: {
    name: network_auxiliary_config.name
    tags: network_auxiliary_config.tags
  }
}

module business_apps_rg '../modules/resources/resource-group/main.bicep' = {
  name:'${business_apps_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, business_apps_rg_config.name))}'
  scope: subscription(business_apps_rg_config.targetSubscriptionId)
  params: {
    name: business_apps_rg_config.name
    tags: business_apps_rg_config.tags
  }
}



