targetScope = 'subscription'

param logging_config object

param network_rg_config object
param vwan_config object
param vhub_config object
param vmx_vhub_config object
param routingintent_config object
param fwpolicy_config object
param fw_config object
param p2svpn_config object
param s2svpn_config object
param vpn_tacvnet01_existing_config object
param bgpconnections_config object



param identity_rg_config object
param identity_vnet_config object
param identity_availability_set_config object
param identity_bastion_config object
param identity_vhub_link_config object
param domain_controller_1_config object
param domain_controller_2_config object

param private_dns_rg_config object
param dns_zone_configs object

param ss_rg_config object
param ss_vnet_config object
param ss_vhub_link_config object
param bastion_config object
param lb_config object
param pls_config object

param vmx_rg_config object
param vmx_vnet_config object
param meraki_vmx_1_config object
param meraki_vmx_2_config object

param vmx_vhub_link_config object


param frontdoor_rg_config object
param frontdoor_config object
param waf_config object


param keyvault_rg_config object
param keyvault_config object

param devops_vmss_rg_config object
// param devops_win_vmss_config object
// param devops_linux_vmss_config object

param dcr_rg_config object
param dcr_config object

param region string
param source_branch string

param existingVwanId string
param existingFwPolicyId string


var is_locked = (source_branch == 'Prod') 

resource vpn_tacvnet01_existing 'Microsoft.Network/localNetworkGateways@2017-06-01' existing = {
  name: vpn_tacvnet01_existing_config.name
  scope: resourceGroup(vpn_tacvnet01_existing_config.targetSubscriptionId, vpn_tacvnet01_existing_config.targetResourceGroup)
}

// -- network resource group and associated resources
module network_rg '../modules/resources/resource-group/main.bicep' = {
  name: '${network_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, network_rg_config.name))}'
  scope: subscription(network_rg_config.targetSubscriptionId)
  params: {
    name: network_rg_config.name
    tags: network_rg_config.tags
    //lock: network_rg_config.lock
  }
}

module vwan 'br/public:avm/res/network/virtual-wan:0.1.1' = if (region == 'WestUS') {
  name:'${vwan_config.name}-${uniqueString(deployment().name, guid(subscription().id, vwan_config.name))}'
  scope: resourceGroup(network_rg_config.targetSubscriptionId, network_rg_config.name)
  dependsOn: [ network_rg ]
  params: {
    name: vwan_config.name
    allowBranchToBranchTraffic: vwan_config.allowBranchToBranchTraffic
    allowVnetToVnetTraffic: vwan_config.allowVnetToVnetTraffic
    disableVpnEncryption: vwan_config.disableVpnEncryption
    type: vwan_config.type
    tags: vwan_config.tags
    lock: is_locked ? vwan_config.lock : null
  }
}

module vhub 'br/public:avm/res/network/virtual-hub:0.1.1' = {
  name: '${vhub_config.name}-${uniqueString(deployment().name, guid(subscription().id, vhub_config.name))}'
  scope: resourceGroup(network_rg_config.targetSubscriptionId, network_rg_config.name)
  dependsOn: [ 
   network_rg  
    // (region == 'WestUS') ? vwan : null
  ]
  params: {
    name: vhub_config.name
    addressPrefix: vhub_config.addressPrefix
    virtualWanId: (region != 'WestUS' ? existingVwanId : vwan.outputs.resourceId) 
    hubVirtualNetworkConnections: vhub_config.hubVirtualNetworkConnections
    tags: vhub_config.tags
    lock: is_locked ? vhub_config.lock : null
  }
}

module vmxhub 'br/public:avm/res/network/virtual-hub:0.1.1' =  {
  name: '${vmx_vhub_config.name}-${uniqueString(deployment().name, guid(subscription().id, vmx_vhub_config.name))}'
  scope: resourceGroup(network_rg_config.targetSubscriptionId, network_rg_config.name)
  dependsOn: [
     network_rg
     //(region == 'WestUS') ? vwan : null
    ]
  params: {
    name: vmx_vhub_config.name
    addressPrefix: vmx_vhub_config.addressPrefix
    virtualWanId: (region != 'WestUS' ? existingVwanId : vwan.outputs.resourceId)
    hubVirtualNetworkConnections: vmx_vhub_config.hubVirtualNetworkConnections
    tags: vmx_vhub_config.tags
    lock: is_locked ? vmx_vhub_config.lock : null
  }
}

module routingintent '../customModules/routing-intent/main.bicep' = {
  name: '${routingintent_config.name}-${uniqueString(deployment().name, guid(subscription().id, routingintent_config.name))}'
  scope: resourceGroup(network_rg_config.targetSubscriptionId, network_rg_config.name)
  dependsOn: [ vwan ]
  params: {
    name: routingintent_config.name
    virtualHubName: vhub.outputs.name
    routingIntentDestinations: routingintent_config.routingIntentDestinations
    routingPolicyName: routingintent_config.routingPolicyName
    routingIntentNextHop: fw.outputs.resourceId
    internetTrafficRoutingPolicy: routingintent_config.internetTrafficRoutingPolicy
    privateTrafficRoutingPolicy: routingintent_config.privateTrafficRoutingPolicy
  }
}


module fw_policy 'br/public:avm/res/network/firewall-policy:0.1.2' = {
  name:'${fwpolicy_config.name}-${uniqueString(deployment().name, guid(subscription().id, fwpolicy_config.name))}'
  scope: resourceGroup(network_rg_config.targetSubscriptionId, network_rg_config.name)
  dependsOn: [ network_rg ]
  params: {
    name: fwpolicy_config.name
    allowSqlRedirect: fwpolicy_config.allowSqlRedirect
    autoLearnPrivateRanges: fwpolicy_config.autoLearnPrivateRanges
    tier: fwpolicy_config.tier
    enableProxy: fwpolicy_config.enableProxy
    servers: fwpolicy_config.servers
    threatIntelMode: fwpolicy_config.threatIntelMode
    mode: fwpolicy_config.mode
    ruleCollectionGroups: fwpolicy_config.ruleCollectionGroups
    tags: fwpolicy_config.tags
    // add lock when available in public module
  }
}


module fw '../customModules/azure-firewall/main.bicep' = {
  name: '${fw_config.name}-${uniqueString(deployment().name, guid(subscription().id, fw_config.name))}'
  scope: resourceGroup(network_rg_config.targetSubscriptionId, network_rg_config.name)
  dependsOn: [
    network_rg
    fw_policy
    vhub 
  ]
  params: {
    name: fw_config.name
    azureSkuTier: fw_config.azureSkuTier
    firewallPolicyId: (region != 'WestUS' ? existingFwPolicyId : fw_policy.outputs.resourceId)
    hubIPAddresses: fw_config.hubIPAddresses
    zones: fw_config.zones
    virtualHubId: vhub.outputs.resourceId
    diagnosticWorkspaceId: logging_config.sentinelWorkspaceId
    tags: fw_config.tags
    lock: is_locked ? fw_config.lock : null
  }
}

module p2svpn '../customModules/p2sVpnGateway/main.bicep' = {
 name:'${p2svpn_config.name}-${uniqueString(deployment().name, guid(subscription().id, p2svpn_config.name))}'
  scope: resourceGroup(network_rg_config.targetSubscriptionId, network_rg_config.name)
  dependsOn: [ fw ]
  params: {
    name: p2svpn_config.name
    aadParams: p2svpn_config.aadParams
    vpnClientIPAddress: p2svpn_config.addressSpace
    fwName: fw.outputs.name
    fwResourceGroup: network_rg_config.name
    fwSubscriptionId: network_rg_config.targetSubscriptionId
    virtualHubId: vhub.outputs.resourceId
    tags: p2svpn_config.tags
  }
}

module s2svpn '../customModules/s2sVpnGateway/main.bicep' = {
  name: '${s2svpn_config.name}-${uniqueString(deployment().name, guid(subscription().id, s2svpn_config.name))}'
  scope: resourceGroup(network_rg_config.targetSubscriptionId, network_rg_config.name)
  dependsOn: [ fw ]
  params: {
    name: s2svpn_config.name
    peer: s2svpn_config.peer
    vhubName: vhub.outputs.name
    vpnConnection_name: s2svpn_config.connectionName
    vpnConnection_linkPsk: s2svpn_config.vpnConnection_linkPsk
  }
}



module vpn_tacvnet01 'br/public:avm/res/network/local-network-gateway:0.1.1' = if (region == 'WestUS' && source_branch == 'Prod') {
  name: '${vpn_tacvnet01_existing_config.name}-${uniqueString(deployment().name, guid(subscription().id, vpn_tacvnet01_existing_config.name))}'
  scope: resourceGroup(vpn_tacvnet01_existing_config.targetSubscriptionId, vpn_tacvnet01_existing_config.targetResourceGroup)
  dependsOn: [ s2svpn, vpn_tacvnet01_existing ]
  params: {
    name: vpn_tacvnet01_existing_config.name
    localGatewayPublicIpAddress: s2svpn.outputs.gatewayPublicIpAddress
    localAsn: string(s2svpn.outputs.vpnGatewayAsn)
    localAddressPrefixes:[]
    localBgpPeeringAddress: vpn_tacvnet01_existing.properties.bgpSettings.bgpPeeringAddress
    lock: is_locked ? vpn_tacvnet01_existing_config.lock : null
  }
}


@sys.batchSize(1)
module bgpConnections '../customModules/bgpConnections/main.bicep' = [for connection in bgpconnections_config.connections: {
  name: '${connection.name}-${uniqueString(deployment().name, guid(subscription().id, connection.name))}'
  scope: resourceGroup(network_rg_config.targetSubscriptionId, network_rg_config.name)
  dependsOn: [ vwan, vmxhub, meraki_vmx_1, meraki_vmx_2 ]
  params: {
    name: connection.name
    hubVirtualNetworkConnectionId: vmx_vhub_link.outputs.resourceId
    peerAsn: connection.peerAsn
    peerIp: connection.peerIp
    vhubName: vmxhub.outputs.name
  }
}] 




// -- identity services resource group and associated resources
module identity_rg '../modules/resources/resource-group/main.bicep' = {
  name:'${identity_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, identity_rg_config.name))}'
  scope: subscription(identity_rg_config.targetSubscriptionId)
  params: {
    name: identity_rg_config.name
    tags: identity_rg_config.tags
    
  }
}

module identity_vnet '../customModules/virtual-network/main.bicep' = {
  name: '${identity_vnet_config.name}-${uniqueString(deployment().name, guid(subscription().id, identity_vnet_config.name))}'
  scope: resourceGroup(identity_rg_config.targetSubscriptionId, identity_rg_config.name)
  dependsOn: [ identity_rg, fw ]
  params: {
    addressPrefixes: [ identity_vnet_config.addressSpace ]
    name: identity_vnet_config.name
    subnets:   identity_vnet_config.subnets  
    flowTimeoutInMinutes: identity_vnet_config.flowTimeoutInMinutes
    tags: identity_vnet_config.tags
    dnsServers: [fw.outputs.privatehubip]
    lock: is_locked ? identity_vnet_config.lock : null
  }
}


module identity_vhub_link '../modules/network/virtual-hub/hub-virtual-network-connection/main.bicep' = {
  name:'${identity_vhub_link_config.name}-${uniqueString(deployment().name, guid(subscription().id, identity_vhub_link_config.name))}'
  scope: resourceGroup(identity_rg_config.targetSubscriptionId, identity_vhub_link_config.targetVhub.rg)
  dependsOn: [ 
    identity_vnet
    vhub
    vwan
  ]
  params: {
    name: identity_vhub_link_config.name
    virtualHubName: identity_vhub_link_config.targetVhub.name
    remoteVirtualNetworkId: identity_vnet.outputs.resourceId
    routingConfiguration: identity_vhub_link_config.routingConfiguration
  }
}

module identity_bastion '../modules/network/bastion-host/main.bicep' = {
  name:'${identity_bastion_config.name}-${uniqueString(deployment().name, guid(subscription().id, identity_bastion_config.name))}'
  scope: resourceGroup(identity_rg_config.targetSubscriptionId, identity_rg_config.name)
  dependsOn: [ identity_rg, identity_vnet, identity_vhub_link ]
  params: {
    name: identity_bastion_config.name
    skuName: identity_bastion_config.skuName
    vNetId: identity_vnet.outputs.resourceId
    diagnosticLogCategoriesToEnable: identity_bastion_config.diagnostics.categories
    diagnosticWorkspaceId: logging_config.sentinelWorkspaceId
    tags: identity_bastion_config.tags
  }
}

module identity_availability_set 'br/public:avm/res/compute/availability-set:0.1.2' = {
  name:'${identity_availability_set_config.name}-${uniqueString(deployment().name, guid(subscription().id, identity_availability_set_config.name))}'
  scope: resourceGroup(identity_rg_config.targetSubscriptionId, identity_rg_config.name)
  dependsOn: [ identity_rg ]
  params: {
    name: identity_availability_set_config.name
    platformFaultDomainCount: identity_availability_set_config.platformFaultDomainCount
    platformUpdateDomainCount: identity_availability_set_config.platformUpdateDomainCount
    tags: identity_availability_set_config.tags
  }
}

module domain_controller_1 '../modules/compute/virtual-machine/main.bicep' = {
  name:'${domain_controller_1_config.name}-${uniqueString(deployment().name, guid(subscription().id, domain_controller_1_config.name))}'
  scope: resourceGroup(identity_rg_config.targetSubscriptionId, identity_rg_config.name)
  dependsOn: [ 
    identity_rg
    identity_availability_set
    identity_vnet
    identity_vhub_link
  ]
  params: {
    name: domain_controller_1_config.name
    availabilitySetResourceId: identity_availability_set.outputs.resourceId
    vmSize: domain_controller_1_config.vmSize
    imageReference: domain_controller_1_config.imageReference
    osDisk: domain_controller_1_config.osDisk
    osType: domain_controller_1_config.osType
    adminUsername: domain_controller_1_config.adminUsername
    adminPassword: domain_controller_1_config.adminPassword
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: identity_vnet.outputs.subnetResourceIds[0]
            privateIPAllocationMethod: domain_controller_1_config.privateIPAllocationMethod 
            privateIPAddress: domain_controller_1_config.privateIPAddress
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    tags: domain_controller_1_config.tags
    lock: is_locked ? domain_controller_1_config.lock : null
  }
}

module domain_controller_2 '../modules/compute/virtual-machine/main.bicep' = {
  name:'${domain_controller_2_config.name}-${uniqueString(deployment().name, guid(subscription().id, domain_controller_2_config.name))}'
  scope: resourceGroup(identity_rg_config.targetSubscriptionId, identity_rg_config.name)
  dependsOn: [ 
    identity_rg
    identity_availability_set
    identity_vnet
    identity_vhub_link
  ]
  params: {
    name: domain_controller_2_config.name
    availabilitySetResourceId: identity_availability_set.outputs.resourceId
    vmSize: domain_controller_2_config.vmSize
    imageReference: domain_controller_2_config.imageReference
    osDisk: domain_controller_2_config.osDisk
    osType: domain_controller_2_config.osType
    adminUsername: domain_controller_2_config.adminUsername
    adminPassword: domain_controller_2_config.adminPassword
    diagnosticWorkspaceId: logging_config.sentinelWorkspaceId
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: identity_vnet.outputs.subnetResourceIds[0]
            privateIPAllocationMethod: domain_controller_2_config.privateIPAllocationMethod
            privateIPAddress: domain_controller_2_config.privateIPAddress
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    tags: domain_controller_2_config.tags
    lock: is_locked ? domain_controller_2_config.lock : null
  }
}

// -- end identity services resource group and associated resources
module private_dns_rg '../modules/resources/resource-group/main.bicep' = {
  name:'${private_dns_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, private_dns_rg_config.name))}'
  scope: subscription(private_dns_rg_config.targetSubscriptionId)
  params: {
    name: private_dns_rg_config.name
    tags: private_dns_rg_config.tags
  }
}



@sys.batchSize(1)
module dns_zones 'br:mcr.microsoft.com/bicep/avm/res/network/private-dns-zone:0.2.1' = [for (zone, index) in dns_zone_configs.names: {
  name: 'dnsZoneDeployment-${index}'
  scope: resourceGroup(private_dns_rg_config.targetSubscriptionId, private_dns_rg_config.name)
  dependsOn: [ private_dns_rg ]
  params: {
    name: zone
    tags: dns_zone_configs.tags
  }
}]
// save hrs of troubleshooting by using batchsize (1) to avoid parallel deployment 
@sys.batchSize(1)
module dns_vnet_link '../modules/network/private-dns-zone/virtual-network-link/main.bicep' = [for (dnsZoneName, index) in dns_zone_configs.names: {
  name: 'dnsVnetLinkDeployment-${index}'
  scope: resourceGroup(private_dns_rg_config.targetSubscriptionId, private_dns_rg_config.name)
  dependsOn: [ dns_zones[index] ]
  params: {
    name: dnsZoneName
    privateDnsZoneName: dnsZoneName
    virtualNetworkResourceId: identity_vnet.outputs.resourceId
    registrationEnabled: dns_zone_configs.registrationEnabled
    tags: dns_zone_configs.tags
  }
}]


//-- shared services resource group and associated resources
module ss_rg '../modules/resources/resource-group/main.bicep' = {
  name: '${ss_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, ss_rg_config.name))}'
  scope: subscription(ss_rg_config.targetSubscriptionId)
  params: {
    name: ss_rg_config.name
    enableDefaultTelemetry: true
    tags: ss_rg_config.tags
   // lock: ss_rg_config.lock
  }
}

module ss_vnet '../customModules/virtual-network/main.bicep' = {
  name: '${ss_vnet_config.name}-${uniqueString(deployment().name, guid(subscription().id, ss_vnet_config.name))}'
  scope: resourceGroup(ss_rg_config.targetSubscriptionId, ss_rg_config.name)
  dependsOn: [ ss_rg, fw, ]
  params: {
    addressPrefixes: [ ss_vnet_config.addressSpace ]
    name: ss_vnet_config.name
    flowTimeoutInMinutes: ss_vnet_config.flowTimeoutInMinutes
    subnets:  ss_vnet_config.subnets
  tags: ss_vnet_config.tags
  dnsServers: [fw.outputs.privatehubip]
  }
}


module ss_vhub_link '../modules/network/virtual-hub/hub-virtual-network-connection/main.bicep' = {
  name:'${ss_vhub_link_config.name}-${uniqueString(deployment().name, guid(subscription().id, ss_vhub_link_config.name))}'
  scope: resourceGroup(ss_rg_config.targetSubscriptionId, ss_vhub_link_config.targetVhub.rg)
  dependsOn: [ 
    ss_vnet
    vhub
    vwan
   ]
  params: {
    name: ss_vhub_link_config.name
    virtualHubName: ss_vhub_link_config.targetVhub.name
    remoteVirtualNetworkId: ss_vnet.outputs.resourceId
    routingConfiguration: ss_vhub_link_config.routingConfiguration
  }
}


module bastion '../modules/network/bastion-host/main.bicep' = {
  name:'${bastion_config.name}-${uniqueString(deployment().name, guid(subscription().id, bastion_config.name))}'
  scope: resourceGroup(ss_rg_config.targetSubscriptionId, ss_rg_config.name)
  dependsOn: [ ss_rg, ss_vnet, ss_vhub_link  ]
  params: {
    name: bastion_config.name
    skuName: bastion_config.skuName
    vNetId: ss_vnet.outputs.resourceId
    diagnosticLogCategoriesToEnable: bastion_config.diagnostics.categories
    diagnosticWorkspaceId: logging_config.sentinelWorkspaceId
    tags: bastion_config.tags
    //lock: is_locked ? bastion_config.lock : null // cuases deployment error
  }
}

module lb '../modules/network/load-balancer/main.bicep' = {
  name: '${lb_config.name}-${uniqueString(deployment().name, guid(subscription().id, lb_config.name))}'
  scope: resourceGroup(ss_rg_config.targetSubscriptionId, ss_rg_config.name)
  dependsOn: [ ss_rg, ss_vnet, bastion ] 
  params: {
    name: lb_config.name
    skuName: lb_config.skuName
    diagnosticWorkspaceId: logging_config.sentinelWorkspaceId
    frontendIPConfigurations: [{
      name: lb_config.frontEndConfig.name
      subnetId: resourceId(ss_rg_config.targetSubscriptionId, ss_rg_config.name, 'Microsoft.Network/virtualNetworks/subnets', ss_vnet_config.name, lb_config.frontEndConfig.subnet)
      privateIPAddress: lb_config.frontEndConfig.ip
    }]
    backendAddressPools: [{
      name: '${lb_config.name}-bepool'
    }]
    probes: lb_config.probes
    tags: lb_config.tags
  }
}

module pls '../modules/network/private-link-service/main.bicep' = {
  name: '${pls_config.name}-${uniqueString(deployment().name, guid(subscription().id, pls_config.name))}'
  scope: resourceGroup(ss_rg_config.targetSubscriptionId, ss_rg_config.name)
  dependsOn: [ ss_rg, ss_vnet, lb ] 
  params: {
    name: pls_config.name
    loadBalancerFrontendIpConfigurations: [{
      id: resourceId(ss_rg_config.targetSubscriptionId, ss_rg_config.name, 'Microsoft.Network/loadBalancers/frontendIpConfigurations', lb_config.name, lb_config.frontEndConfig.name)
    }]
    ipConfigurations: [{
      name: pls_config.subnetConfig.name
      properties: {
        privateIPAllocationMethod: pls_config.subnetConfig.method
        privateIPAddress: pls_config.subnetConfig.ip
        subnet: {
          id: resourceId(ss_rg_config.targetSubscriptionId, ss_rg_config.name, 'Microsoft.Network/virtualNetworks/subnets', ss_vnet_config.name, pls_config.subnetConfig.name)
        }
        primary: pls_config.subnetConfig.isPrimary
      }
    }]
    tags: pls_config.tags
  }
}

// -- meraki resource group and associated resources
module vmx_rg '../modules/resources/resource-group/main.bicep' = {
  name: '${vmx_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, vmx_rg_config.name))}'
  scope: subscription(vmx_rg_config.targetSubscriptionId)
  params: {
    name: vmx_rg_config.name
    tags: vmx_rg_config.tags
    //lock: vmx_rg_config.lock
  }
}


module vmx_vnet '../customModules/virtual-network/main.bicep' = {
  name: '${vmx_vnet_config.name}-${uniqueString(deployment().name, guid(subscription().id, vmx_vnet_config.name))}'
  scope: resourceGroup(vmx_rg_config.targetSubscriptionId,  vmx_rg_config.name)
  dependsOn: [ vmx_rg ]
  params: {
    addressPrefixes: [ vmx_vnet_config.addressSpace ]
    name: vmx_vnet_config.name
    subnets:   vmx_vnet_config.subnets  
    flowTimeoutInMinutes: vmx_vnet_config.flowTimeoutInMinutes
    //dnsServers: [fw.outputs.privatehubip] // this is not needed as the dns servers are inherited from the vnet using azure dns
    tags: vmx_vnet_config.tags
  }
}


module meraki_vmx_1 '../customModules/meraki-vmx/main.bicep' = {
  name:'${meraki_vmx_1_config.vmName}-${uniqueString(deployment().name, guid(subscription().id, meraki_vmx_1_config.vmName))}'
  scope: resourceGroup(vmx_rg_config.targetSubscriptionId, vmx_rg_config.name)
  dependsOn: [ vmx_rg, vmx_vnet, vmxhub ]
  params: {
    vmName: meraki_vmx_1_config.vmName
    merakiAuthToken: meraki_vmx_1_config.merakiAuthToken
    applicationResourceName: meraki_vmx_1_config.applicationResourceName
    virtualNetworkName: vmx_vnet.outputs.name 
    virtualNetworkNewOrExisting: meraki_vmx_1_config.virtualNetworkNewOrExisting
    virtualNetworkAddressPrefix: vmx_vnet.outputs.addressSpace[0] 
    virtualNetworkResourceGroup: vmx_rg.outputs.name 
    virtualMachineSize: meraki_vmx_1_config.virtualMachineSize
    subnetName: vmx_vnet.outputs.subnetNames[0] 
    subnetAddressPrefix:  vmx_vnet.outputs.subnetAddressPrefixes[0] 
  }
}

module meraki_vmx_2 '../customModules/meraki-vmx/main.bicep' = {
  name:'${meraki_vmx_2_config.vmName}-${uniqueString(deployment().name, guid(subscription().id, meraki_vmx_2_config.vmName))}'
  scope: resourceGroup(vmx_rg_config.targetSubscriptionId, vmx_rg_config.name)
  dependsOn: [ vmx_rg, vmx_vnet, vmxhub ]
  params: {
    vmName: meraki_vmx_2_config.vmName
    merakiAuthToken: meraki_vmx_2_config.merakiAuthToken
    applicationResourceName: meraki_vmx_2_config.applicationResourceName
    virtualNetworkName: vmx_vnet.outputs.name 
    virtualNetworkNewOrExisting: meraki_vmx_2_config.virtualNetworkNewOrExisting
    virtualNetworkAddressPrefix: vmx_vnet.outputs.addressSpace[0] 
    virtualNetworkResourceGroup: vmx_rg.outputs.name 
    virtualMachineSize: meraki_vmx_2_config.virtualMachineSize
    subnetName: vmx_vnet.outputs.subnetNames[1] 
    subnetAddressPrefix:  vmx_vnet.outputs.subnetAddressPrefixes[1] 
  }
}


module vmx_vhub_link '../modules/network/virtual-hub/hub-virtual-network-connection/main.bicep' = {
  name:'${vmx_vhub_link_config.name}-${uniqueString(deployment().name, guid(subscription().id, vmx_vhub_link_config.name))}'
  scope: resourceGroup(vmx_rg_config.targetSubscriptionId, vmx_vhub_link_config.targetVhub.rg)
  dependsOn: [ 
    vmx_vnet
    vmxhub
    vwan
  ]
  params: {
    name: vmx_vhub_link_config.name
    virtualHubName: vmx_vhub_link_config.targetVhub.name
    remoteVirtualNetworkId: vmx_vnet.outputs.resourceId
    routingConfiguration: vmx_vhub_link_config.routingConfiguration
  }
}

// End of Meraki vMX 1 resources




// -- front door resource group and associated resources
module frontdoor_rg '../modules/resources/resource-group/main.bicep' = if (region == 'WestUS' && source_branch == 'Prod') {
  name: '${frontdoor_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, frontdoor_rg_config.name))}'
  scope: subscription(frontdoor_rg_config.targetSubscriptionId)
  params: {
    name: frontdoor_rg_config.name
    tags: frontdoor_rg_config.tags
    //lock: frontdoor_rg_config.lock
  }
}

module waf 'br:mcr.microsoft.com/bicep/avm/res/network/front-door-web-application-firewall-policy:0.1.1' = if (region == 'WestUS' && source_branch == 'Prod') {
  name: '${waf_config.name}-${uniqueString(deployment().name, guid(subscription().id, waf_config.name))}'
  scope: resourceGroup(frontdoor_rg_config.targetSubscriptionId, frontdoor_rg_config.name)
  dependsOn: [ frontdoor_rg ]
  params: {
    name: waf_config.name
    location: 'global'
    managedRules: waf_config.managedRules
    policySettings: waf_config.policySettings
    sku: waf_config.sku
    customRules: waf_config.customRules
    tags: waf_config.tags
  }
}



// figure out how to send front door logs to sentinel.
module frontdoor '../customModules/cdn/main.bicep' = if (region == 'WestUS' && source_branch == 'Prod') {
  name: '${frontdoor_config.name}-${uniqueString(deployment().name, guid(subscription().id, frontdoor_config.name))}'
  scope: resourceGroup(frontdoor_rg_config.targetSubscriptionId, frontdoor_rg_config.name)
  dependsOn: [ frontdoor_rg, ((region == 'WestUS' && source_branch == 'Prod') ? waf: null) ]
  params: {
    name: frontdoor_config.name
    location: 'global'
    sku: frontdoor_config.sku
    afdEndpoints: frontdoor_config.afdEndpoints
    customDomains: frontdoor_config.customDomains
    originResponseTimeoutSeconds: frontdoor_config.originResponseTimeoutSeconds
    originGroups: frontdoor_config.originGroups
    securityPolicy: [
      {
        name: frontdoor_config.securityPolicy[0].name
        associations: [for i in range(0, length(frontdoor_config.afdEndpoints)): {
          domains: [
            {
              id: resourceId(frontdoor_rg_config.targetSubscriptionId, frontdoor_rg_config.name, 'Microsoft.Cdn/profiles/afdendpoints', frontdoor_config.name, frontdoor_config.afdEndpoints[i].name)
            }
            {
              id: resourceId(frontdoor_rg_config.targetSubscriptionId, frontdoor_rg_config.name, 'Microsoft.Cdn/profiles/customdomains', frontdoor_config.name, frontdoor_config.customDomains[i].name)
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }]
        wafPolicy: ((region == 'WestUS' && source_branch == 'Prod') ? waf.outputs.resourceId: null)
      }
    ]
    tags: frontdoor_config.tags
  }
}




module keyvault_rg '../modules/resources/resource-group/main.bicep' = {
  name: '${keyvault_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, keyvault_rg_config.name))}'
  scope: subscription(keyvault_rg_config.targetSubscriptionId)
  params: {
    name: keyvault_rg_config.name
    tags: keyvault_rg_config.tags
  }
}

module keyvault 'br/public:avm/res/key-vault/vault:0.4.0' = {
  scope: resourceGroup(keyvault_rg_config.targetSubscriptionId, keyvault_rg_config.name)
  name: '${keyvault_config.name}-${uniqueString(deployment().name, guid(subscription().id, keyvault_config.name))}'
  dependsOn: [ keyvault_rg ]
  params: {
    name: keyvault_config.name
  }
}

module devops_vmss_rg '../modules/resources/resource-group/main.bicep' = {
  name: '${devops_vmss_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, devops_vmss_rg_config.name))}'
  scope: subscription(devops_vmss_rg_config.targetSubscriptionId)
  params: {
    name: devops_vmss_rg_config.name
    tags: devops_vmss_rg_config.tags
  }
}




module dcr_rg '../modules/resources/resource-group/main.bicep' = {
  name: '${dcr_rg_config.name}-${uniqueString(deployment().name, guid(subscription().id, dcr_rg_config.name))}'
  scope: subscription(dcr_rg_config.targetSubscriptionId)
  params: {
    name: dcr_rg_config.name
    tags: dcr_rg_config.tags
  }
}

module dcr '../modules/insights/data-collection-rule/main.bicep' = if (region == 'WestUS'){
  name: '${dcr_config.name}-${uniqueString(deployment().name, guid(subscription().id, dcr_config.name))}'
  scope: resourceGroup(dcr_rg_config.targetSubscriptionId, dcr_rg_config.name)
  dependsOn: [dcr_rg]
  params: {
    name: dcr_config.name
    dataFlows: dcr_config.dataFlows
    dataSources: dcr_config.dataSources
    destinations: dcr_config.destinations
    kind: dcr_config.kind
    tags: dcr_config.tags
  }
}
