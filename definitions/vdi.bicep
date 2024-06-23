targetScope = 'subscription'

param logging_config object

param network_rg_config object
param vdi_vnet_config object
param vhub_link_config object
param network_auxiliary_rg_config object
param hub_fw_config object

param vdi_rg_config object
param vdi_hostpool_config object
param vdi_appgroup_config object
param vdi_workspace_config object


// use this format 'name: ${identity_vnet_config.name}-${uniqueString(deployment().name, guid(subscription().id, identity_vnet_config.name))}' instead of ' name: uniqueString(deployment().name, guid(subscription().id, identity_rg_config.name))' to avoid ambiguius deployment names 

// REFERENCE EXISTING RESOURCES
resource hub_fw 'Microsoft.Network/azureFirewalls@2020-11-01' existing = {
  name: hub_fw_config.name
  scope: resourceGroup(hub_fw_config.subId, hub_fw_config.rgName)
}

module network_rg '../modules/resources/resource-group/main.bicep' = {
  name: '${network_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, network_rg_config.name))}'
  scope: subscription(network_rg_config.targetSubscriptionId)
  params: {
    name: network_rg_config.name
    tags: network_rg_config.tags
  }
}

module vdi_vnet '../customModules/virtual-network/main.bicep' = {
  name: '${vdi_vnet_config.name}-${uniqueString(deployment().name, guid(subscription().id, vdi_vnet_config.name))}'
  scope: resourceGroup(network_rg_config.targetSubscriptionId, network_rg_config.name)
  dependsOn: [network_rg]
  params: {
    addressPrefixes: [vdi_vnet_config.addressSpace]
    name: vdi_vnet_config.name
    flowTimeoutInMinutes: vdi_vnet_config.flowTimeoutInMinutes
    subnets: vdi_vnet_config.subnetConfigs
    tags: vdi_vnet_config.tags
    dnsServers: [hub_fw.properties.hubIPAddresses.privateIPAddress]
  }
}

module vhub_link '../modules/network/virtual-hub/hub-virtual-network-connection/main.bicep'= {
  name: '${vhub_link_config.name}-${uniqueString(deployment().name, guid(subscription().id, vhub_link_config.name))}'
  scope: resourceGroup(vhub_link_config.targetVhub.subId, vhub_link_config.targetVhub.rg)
  dependsOn: [vdi_vnet]
  params: {
    name: vhub_link_config.name
    virtualHubName: vhub_link_config.targetVhub.name
    remoteVirtualNetworkId: vdi_vnet.outputs.resourceId
    routingConfiguration: vhub_link_config.routingConfiguration
  }
}

module network_auxiliary_rg '../modules/resources/resource-group/main.bicep' = {
  name: '${network_auxiliary_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, network_auxiliary_rg_config.name))}' 
  scope: subscription(network_auxiliary_rg_config.targetSubscriptionId)
  params: {
    name: network_auxiliary_rg_config.name
    tags: network_auxiliary_rg_config.tags
  }
}

module vdi_rg '../modules/resources/resource-group/main.bicep' = {
  name: '${vdi_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, vdi_rg_config.name))}'
  scope: subscription(vdi_rg_config.targetSubscriptionId)
  params: {
    name: vdi_rg_config.name
    tags: vdi_rg_config.tags
  }
}

module vdi_hostpool '../modules/desktop-virtualization/host-pool/main.bicep' ={
  name: '${vdi_hostpool_config.name}-${uniqueString(deployment().name, guid(subscription().id, vdi_hostpool_config.name))}'
  scope: resourceGroup(vdi_rg_config.targetSubscriptionId, vdi_rg_config.name)
  dependsOn: [vdi_rg, vdi_vnet, vhub_link]
  params:{
    name: vdi_hostpool_config.name
    friendlyName: vdi_hostpool_config.friendlyName
    type: vdi_hostpool_config.type
    personalDesktopAssignmentType: vdi_hostpool_config.personalDesktopAssignmentType
    customRdpProperty: vdi_hostpool_config.customRdpProperty
    validationEnvironment: false
    diagnosticWorkspaceId: logging_config.sentinelWorkspaceId
    agentUpdateType: vdi_hostpool_config.agentUpdateType
    agentUpdateMaintenanceWindowTimeZone: vdi_hostpool_config.agentUpdateMaintenanceWindowTimeZone
    tags: vdi_hostpool_config.tags
  }
}

module vdi_appgroup '../modules/desktop-virtualization/application-group/main.bicep' = {
  name: '${vdi_appgroup_config.name}-${uniqueString(deployment().name, guid(subscription().id, vdi_appgroup_config.name))}'
  scope: resourceGroup(vdi_rg_config.targetSubscriptionId, vdi_rg_config.name)
  dependsOn: [vdi_hostpool]
  params: {
    name: vdi_appgroup_config.name
    friendlyName: vdi_appgroup_config.friendlyName
    applicationGroupType: vdi_appgroup_config.applicationGroupType
    hostpoolName: vdi_hostpool.outputs.name
    diagnosticWorkspaceId: logging_config.sentinelWorkspaceId
    tags: vdi_appgroup_config.tags
  }
}

module vdi_workspace '../modules/desktop-virtualization/workspace/main.bicep' = {
  name: '${vdi_workspace_config.name}-${uniqueString(deployment().name, guid(subscription().id, vdi_workspace_config.name))}'
  scope: resourceGroup(vdi_rg_config.targetSubscriptionId, vdi_rg_config.name)
  dependsOn: [vdi_appgroup]
  params: {
    name: vdi_workspace_config.name
    friendlyName: vdi_workspace_config.friendlyName
    appGroupResourceIds: [vdi_appgroup.outputs.resourceId]
    diagnosticWorkspaceId: logging_config.sentinelWorkspaceId
    tags: vdi_workspace_config.tags
  }
}


