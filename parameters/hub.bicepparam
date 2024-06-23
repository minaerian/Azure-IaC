using '../definitions/hub.bicep'


var iac_env = readEnvironmentVariable('iac_env', 'dev')


var scope_prefix = 'platform'

var location = readEnvironmentVariable('location_suffix', 'wus')
var gmr_com_DNS_resourceId = '/subscriptions/5dca793e-3f0d-4e8c-a1a6-dc5d84a5b5a2/resourceGroups/asomdomains/providers/Microsoft.Network/dnszones/gmr.com'
var iag_com_DNS_resourceId = '/subscriptions/5dca793e-3f0d-4e8c-a1a6-dc5d84a5b5a2/resourceGroups/IAGDomains/providers/Microsoft.Network/dnszones/iag.com'
var full_location = readEnvironmentVariable('location', 'WestUS')

var deployment_scopes = {
  dev: {
    hubSubscriptionId: 'd1e2f3g4-1234-5678-9abc-def012345678' //Platform-Dev-Hub
    vhub_addressSpace: '10.10.0.0/24'
    ss_vnet_prefix: '10.10'
    p2s_addressSpace: '172.16.172.0/22'
    existingVwanResourceId: ''
    existingFwPolicyResourceId: ''
  }
  prod: {
    hubSubscriptionId: 'b1c2d3e4-5678-9abc-def0-123456789abc' //Platform-Sub-prod
    vhub_addressSpace: '10.10.0.0/24'
    ss_vnet_prefix: '10.10'
    p2s_addressSpace: '172.16.172.0/22'
    existingVwanResourceId: ''
    existingFwPolicyResourceId: ''
  }
  drdev: {
    hubSubscriptionId: 'f1g2h3i4-1234-5678-9abc-def012345678' // dr-platform-sub-dev-hub
    vhub_addressSpace: '10.110.0.0/24'
    ss_vnet_prefix: '10.110'
    p2s_addressSpace: '172.16.180.0/22'
    existingVwanResourceId: '/subscriptions/d1e2f3g4-1234-5678-9abc-def012345678/resourceGroups/platform-network-rg-dev-wus/providers/Microsoft.Network/virtualWans/platform-vwan-dev-wus'
    existingFwPolicyResourceId: '/subscriptions/d1e2f3g4-1234-5678-9abc-def012345678/resourceGroups/platform-network-rg-dev-wus/providers/Microsoft.Network/firewallPolicies/platform-fw-policy-dev-wus'
  }
  drprod: {
    hubSubscriptionId: 'h1i2j3k4-5678-9abc-def0-123456789abc' //dr-Platform-Sub-prod
    vhub_addressSpace: '10.110.0.0/24'
    ss_vnet_prefix: '10.110'
    p2s_addressSpace: '172.16.180.0/22'
    existingVwanResourceId: '/subscriptions/b1c2d3e4-5678-9abc-def0-123456789abc/resourceGroups/platform-network-rg-prod-wus/providers/Microsoft.Network/virtualWans/platform-vwan-prod-wus'
    existingFwPolicyResourceId: '/subscriptions/b1c2d3e4-5678-9abc-def0-123456789abc/resourceGroups/platform-network-rg-prod-wus/providers/Microsoft.Network/firewallPolicies/platform-fw-policy-prod-wus'
  }
}

var currentEnvironment = deployment_scopes[toLower(iac_env)]
var hub_subscriptionId = currentEnvironment.hubSubscriptionId
var vhub_addressSpace =  currentEnvironment.vhub_addressSpace
var ss_vnet_prefix = currentEnvironment.ss_vnet_prefix
var p2s_addressSpace = currentEnvironment.p2s_addressSpace
//var existingVwanResourceId = currentEnvironment.existingVwanResourceId

param existingVwanId = currentEnvironment.existingVwanResourceId
param existingFwPolicyId = currentEnvironment.existingFwPolicyResourceId
param region = full_location // used in hub.bicep to conditionaly deploy resources based on location
param source_branch = iac_env // used in hub.bicep to conditionaly deploy resources based on branch name

var common_tags = {
  CreatedBy: 'Bicep'
  Environment: iac_env
  DeployedBy: 'iac_${iac_env}'
}

param logging_config = {
  sentinelWorkspaceId: '/subscriptions/5dca793e-3f0d-4e8c-a1a6-dc5d84a5b5a2/resourcegroups/plf-rg-sentinel-wu-01/providers/microsoft.operationalinsights/workspaces/plf-log-sentinel-wu-01'
}

param network_rg_config = {
  name: '${scope_prefix}-network-rg-${toLower(iac_env)}-${location}'
  targetSubscriptionId: hub_subscriptionId
  tags: {
    CreatedBy: 'Bicep'
    Environment: iac_env
    'hidden-title': 'Core networking for ${iac_env} environment'
  }
  lock: 'CanNotDelete'
}

param vwan_config = {
  name: '${scope_prefix}-vwan-${toLower(iac_env)}-${location}'
  allowBranchToBranchTraffic: true
  allowVnetToVnetTraffic: true
  disableVpnEncryption: false
  type: 'Standard'
  tags: common_tags
  lock: {
    name: 'vwan-lock'
    kind: 'CanNotDelete'
    notes: 'This resource is locked to prevent accidental deletion.'
  }
}

param vhub_config = {
  name: '${scope_prefix}-vhub-${toLower(iac_env)}-${location}'
  addressPrefix: vhub_addressSpace
  hubVirtualNetworkConnections: []
tags: common_tags
  lock: {
    name: 'vhub-lock'
    kind: 'CanNotDelete'
    notes: 'This resource is locked to prevent accidental deletion.'
  }
}

param vmx_vhub_config = {
  name: '${scope_prefix}-vmx-vhub-${toLower(iac_env)}-${location}'
  addressPrefix: '${ss_vnet_prefix}.32.0/24'
  hubVirtualNetworkConnections: []
tags: common_tags
  lock: {
    name: 'vmx-vhub-lock'
    kind: 'CanNotDelete'
    notes: 'This resource is locked to prevent accidental deletion.'
  }
}

param routingintent_config = {
  name: 'vhub-routingintent-${toLower(iac_env)}-${location}'
  routingIntentDestinations: [
    'Internet' 
    'PrivateTraffic' 
  ]
  routingPolicyName: 'allTrafficToAZFirewall'
  internetTrafficRoutingPolicy: true // Set to true if you want to route Internet traffic
  privateTrafficRoutingPolicy: true // Set to true if you want to route Private traffic
}


param fwpolicy_config = {
  name: '${scope_prefix}-fw-policy-${toLower(iac_env)}-${location}'
  allowSqlRedirect: false
  autoLearnPrivateRanges: 'Enabled'
  tier: 'Premium'
  enableProxy: true
  mode: 'Alert' //The operation mode for Intrusion Detection. Possible values are Alert, Deny, and Off. 
  threatIntelMode: 'Alert' //The operation mode for Threat Intelligence. Possible values are Alert, Deny, and Off.
  servers: [
    domain_controller_1_config.privateIPAddress
    domain_controller_2_config.privateIPAddress
    ]
  ruleCollectionGroups: [
    // Network Rule Collection Group WestUS
    {
      name: '${scope_prefix}-networkRuleCollectionGroup-${toLower(iac_env)}-${location}'
      priority: 4000
      ruleCollections: [
        {
          action: {
            type: 'Allow'
          }
          name: '${scope_prefix}-networkRuleCollection-${toLower(iac_env)}-${location}'
          priority: 4555
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          rules: [
            {
              destinationAddresses: [
                '*'
              ]
              destinationFqdns: []
              destinationIpGroups: []
              destinationPorts: [
                '*'
              ]
              ipProtocols: [
                'TCP'
                'UDP'
                'ICMP'
              ]
              name: 'allow all private traffic'
              ruleType: 'NetworkRule'
              sourceAddresses: [
              '10.20.0.0/20' //gmr prod
              '10.79.0.0/20' //gmr dev
              '10.78.0.0/20' //gmr qa
              '10.20.224.0/20' //gmr vdi
              '10.30.0.0/20' //iag prod
              '10.72.0.0/20' //iag dev
              '10.73.0.0/20' //iag qa
              '10.30.224.0/20' //iag vdi
              '10.10.16.0/20' //sharedservices
              '10.10.8.0/24' //Meraki vNet
              '10.10.0.0/24' //vhub
              '172.16.172.0/22' //p2s vpn
              '10.10.3.0/24' //identity vnet
              '10.50.0.0/20' //azf prod
              '10.60.0.0/16' // old network
              '10.100.0.0/16' // TACVNET01
              '10.101.0.0/16' // TACVNET01
              '10.102.0.0/16' // TACVNET01
              '10.200.0.0/16' // TACVNET01
              '172.16.255.0/24' // glendon MX
              '10.0.100.0/23' // glendon MX
              '192.168.16.0/21' // glendon MX
              '10.0.10.0/23' // glendon MX AzoffData
              '192.168.99.0/24' // glendon MX
              '172.16.101.0/24' // glendon MX
              '172.16.100.0/24' // glendon MX
              '10.0.14.0/24' // glendon MX  AzoffMgmt
              '10.0.16.0/24' // glendon MX 	IoT
              '10.0.20.0/24' // glendon MX 	Data_10FL
              '10.0.21.0/24' // glendon MX	Data_12FL
              '10.0.22.0/24' // glendon MX	Data_20FL
              '10.0.23.0/24' // glendon MX	Data_21FL
              '10.0.24.0/24' // glendon MX Data_7FL
              '172.0.0.0/24' // old point to site aka TACVPN_GW01
              ]
              sourceIpGroups: []
            }
          ]
        }
      ]
    } 
    // Application Rule Collection Group Westus
    {
      name: '${scope_prefix}-applicationRuleCollectionGroup-${toLower(iac_env)}-${location}'
      priority: 5000
      ruleCollections: [
        {
          action: {
            type: 'Allow'
          }
          name: '${scope_prefix}-applicationRuleCollection-${toLower(iac_env)}-${location}'
          priority: 5555
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          rules: [
            {
              description: ''
              name: 'allow all private traffic'
              ruleType: 'ApplicationRule'
              protocols: [
                {
                  port: 443
                  protocolType: 'https'
                }
                {
                  port: 80
                  protocolType: 'http'
                }
              ]
              sourceAddresses: [
                '*'
              ]
              //sourceIpGroups: []
              targetFqdns: [
                'cacerts.digicert.com' // required for published powerbi semantic model refresh to work. 
              ]
              //targetUrls: []
              terminateTLS: false
              // webCategories: []
            }
          ]
        }
      ]
    } 
    // Network Rule Collection Group EastUS 
    {
      name: '${scope_prefix}-networkRuleCollectionGroup-${toLower(iac_env)}-eastus'
      priority: 5000
      ruleCollections: [
        {
          action: {
            type: 'Allow'
          }
          name: '${scope_prefix}-networkRuleCollection-${toLower(iac_env)}-eastus'
          priority: 5555
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          rules: [
            {
              destinationAddresses: [
                '*'
              ]
              destinationFqdns: []
              destinationIpGroups: []
              destinationPorts: [
                '*'
              ]
              ipProtocols: [
                'TCP'
                'UDP'
                'ICMP'
              ]
              name: 'allow all private traffic'
              ruleType: 'NetworkRule'
              sourceAddresses: [
              '10.110.3.0/24' //identity vnet
              '10.110.32.0/24' //Meraki vNet
              '10.110.0.0/24' //vhub
              '10.110.16.0/20' //sharedservices
              '10.173.0.0/20' //iag qa
              '10.130.0.0/20' //iag prod
              '10.172.0.0/20' //iag dev
              '10.130.224.0/20' //iag vdi
              '10.178.0.0/20' //gmr qa
              '10.120.0.0/20' //gmr prod
              '10.179.0.0/20' //gmr dev
              '10.120.224.0/20' //gmr vdi
              '10.150.0.0/20' //azf prod
              '172.16.180.0/22' //p2s vpn
              ]
            }
          ]
        }
      ]
    }
   ]
  tags: common_tags
}

param fw_config = {
  name: '${scope_prefix}-fw-${toLower(iac_env)}-${location}'
  azureSkuTier: 'Premium'
  hubIPAddresses: {
    publicIPs: {
      count: 1
    }
  }
  zones: []
  tags: common_tags
  lock: 'CanNotDelete'
}

param p2svpn_config = {
  name: '${scope_prefix}-p2svpn-${toLower(iac_env)}-${location}'
  addressSpace: p2s_addressSpace
  aadParams: {
    aadAudience: '41b23e61-6c1e-4545-b367-cd054ehdjfkb4'
    aadIssuer: 'https://sts.windows.net/e6775d1a-9e02-49ad-a2de-19fa4c0a1078/'
    aadTenant: 'https://login.microsoftonline.com/e6775d1a-9e02-49ad-a2de-19fa4c0a1078'
  }
  tags: common_tags
}

param s2svpn_config = {
  name: '${scope_prefix}-s2s-gateway-${toLower(iac_env)}-${location}'
  peer: {
    name: 'TACVPN_GW01'
    gwIpName: 'TACVPN_GW01_IP'
    subId: '5dca793e-3f0d-4e8c-a1a6-dc5d84a5b5a2'
    rgName: 'TAC_FW01'
  }
  connectionName: 'TACVNET01-gateway'
  vpnConnection_linkPsk: 'HWJ1ryb7vyx5kda@zdn'
}

param vpn_tacvnet01_existing_config = {
  name: 'to-platform-vhub-prod-${location}'
  targetSubscriptionId: '5dca793e-3f0d-4e8c-a1a6-dc5d84a5b5a2'
  targetResourceGroup: 'TAC_FW01'
  lock: {
    name: 'vpn-tacvnet01-lock'
    kind: 'CanNotDelete'
    notes: 'This resource is locked to prevent accidental deletion.'
  }
}


param bgpconnections_config = {
  connections: [
    {
      name: 'vmx1'
      peerAsn: 64512
      peerIp: '${ss_vnet_prefix}.8.4' // private IP of the VMX1  
    }
    {
      name: 'vmx2'
      peerAsn: 64512
      peerIp: '${ss_vnet_prefix}.8.36' // private IP of the VMX2 
    }
  ]
}


param identity_rg_config = {
  name: '${scope_prefix}-identity-rg-${toLower(iac_env)}-${location}'
  targetSubscriptionId: hub_subscriptionId
  tags: common_tags
  lock: 'CanNotDelete'
}

param identity_vnet_config = {
  
  name: '${scope_prefix}-identity-vnet-${toLower(iac_env)}-${location}'
  addressSpace: '${ss_vnet_prefix}.3.0/24'
  flowTimeoutInMinutes: 20
  subnets: [ // ORDER OF DEPLOYMENT - CHANGE WITH CAUTION
    {
      name: 'subnet-identity-${toLower(iac_env)}' //index 0
      addressPrefix: '${ss_vnet_prefix}.3.0/28'
    }
    {
      name: 'AzureBastionSubnet' //index 1
      addressPrefix: '${ss_vnet_prefix}.3.16/28'
    }
  ]
  tags: common_tags
  lock:'CanNotDelete'
}

param identity_vhub_link_config = {
  name: 'vhub-link-identity-${toLower(iac_env)}-${location}'
  targetVhub: {
    name: vhub_config.name
    rg: network_rg_config.name
  }
  routingConfiguration: {}
}

param identity_bastion_config = {
  name: '${scope_prefix}-identity-bastion-${toLower(iac_env)}-${location}'
  skuName: 'Standard'
  diagnostics: {
    categories: ['BastionAuditLogs']
  }
  tags: common_tags
}

param identity_availability_set_config = {
  name: '${scope_prefix}-identity-avset-${toLower(iac_env)}-${location}'
  platformFaultDomainCount: 2
  platformUpdateDomainCount: 5
  tags: common_tags
}

param domain_controller_1_config = {
  name: 'dc1-${toLower(iac_env)}-${location}'
  vmSize: 'Standard_D2s_v3'
  imageReference: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  osDisk: {
    caching: 'ReadWrite'
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
    diskSizeGB: 128
  }
  osType: 'Windows'
  adminUsername: 'localaddy'
  adminPassword: 'FXe4gTzZnktkq!2'
  privateIPAllocationMethod: 'Static'
  privateIPAddress: '${ss_vnet_prefix}.3.5'
  tags: common_tags
  lock: 'CanNotDelete'
}

param domain_controller_2_config = {
  name: 'dc2-${toLower(iac_env)}-${location}'
  vmSize: 'Standard_D2s_v3'
  imageReference: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  osDisk: {
    caching: 'ReadWrite'
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
    diskSizeGB: 128
  }
  osType: 'Windows'
  adminUsername: 'localaddy'
  adminPassword: 'FXe4gTzZnktkq!2'
  privateIPAllocationMethod: 'Static'
  privateIPAddress: '${ss_vnet_prefix}.3.4'
  availabilityZone: 0
  tags: common_tags
  lock: 'CanNotDelete'
}

//Begin shared services 
param ss_rg_config = {
  name: '${scope_prefix}-ss-rg-${toLower(iac_env)}-${location}'
  targetSubscriptionId: hub_subscriptionId
  tags: common_tags
  lock: 'CanNotDelete'
}

param ss_vhub_link_config = {
  name: 'ss-vnet-vhub-link-${toLower(iac_env)}-${location}'
  targetVhub: {
    name: vhub_config.name
    rg: network_rg_config.name
  }
  routingConfiguration: {}
}


param ss_vnet_config = {
  name: '${scope_prefix}-ss-vnet-${toLower(iac_env)}-${location}'
  addressSpace: '${ss_vnet_prefix}.16.0/20'
  flowTimeoutInMinutes: 20
  subnets: [ // ORDER OF DEPLOYMENT - CHANGE WITH CAUTION other resource depend on this order in the array
    {
      name: 'AzureBastionSubnet' // index 0
      addressPrefix: '${ss_vnet_prefix}.16.0/26'
    }
    {
      name: 'subnet-lb-${toLower(iac_env)}' // index 1
      addressPrefix: '${ss_vnet_prefix}.16.128/26'
    }
    {
      name: 'subnet-pls-${toLower(iac_env)}' // index 2
      addressPrefix: '${ss_vnet_prefix}.16.192/26'
      privateLinkServiceNetworkPolicies: 'Disabled'
    }
    {
      name: 'default-subnet-${toLower(iac_env)}' // index 3
      addressPrefix: '${ss_vnet_prefix}.17.0/26'
      serviceEndpoints:[
        {service: 'Microsoft.Storage.Global'}
      ]
    }
    {
      name: 'subnet-appgw-${toLower(iac_env)}' // index 4
      addressPrefix: '${ss_vnet_prefix}.17.64/26'
      serviceEndpoints:[
        {service: 'Microsoft.Storage.Global'}
      ]
    }
    {
      name: 'subnet-private-endpoint-${toLower(iac_env)}' // index 5
      addressPrefix: '${ss_vnet_prefix}.17.128/25'
    }
  ]
  tags: common_tags
}

param bastion_config = {
  name: '${scope_prefix}-bastion-${toLower(iac_env)}-${location}'
  skuName: 'Standard'
  diagnostics: {
    categories: ['BastionAuditLogs']
  }
  tags: common_tags
}

param lb_config = {
  name: '${scope_prefix}-lb-${toLower(iac_env)}-${location}'
  skuName: 'Standard'
  frontEndConfig: {         // see ss_vnet_config for subnet and IP details
    name: '${scope_prefix}-lb-${toLower(iac_env)}-${location}-frontendip'
    subnet: 'subnet-lb-${toLower(iac_env)}' // this is created in the ss_vnet_config param
    ip: '${ss_vnet_prefix}.16.134'      // this scope is set in the ss_vnet_config param
  }
  probes: [{
    name: '${scope_prefix}-lb-${toLower(iac_env)}-${location}-probe'
    protocol: 'Tcp'
    port: 80
    intervalInSeconds: 15
    numberOfProbes: 2
  }]
  tags: common_tags
}

param pls_config = {
  name: '${scope_prefix}-pls-${toLower(iac_env)}-${location}'
  subnetConfig: {
    name: 'subnet-pls-${toLower(iac_env)}'
    ip: '${ss_vnet_prefix}.16.198'
    method: 'Static'
    isPrimary: false
  }
  tags: common_tags
}

// end shared services
param vmx_rg_config = {
  name: '${scope_prefix}-meraki-rg-${toLower(iac_env)}-${location}'
  targetSubscriptionId: hub_subscriptionId
  tags: common_tags
  lock: 'CanNotDelete'
}


param vmx_vnet_config = {
  name: '${scope_prefix}-meraki-vnet-${toLower(iac_env)}-${location}'
  addressSpace: '${ss_vnet_prefix}.8.0/24'
  flowTimeoutInMinutes: 20
  subnets: [ // ORDER OF DEPLOYMENT - CHANGE WITH CAUTION other resource depend on this order in the array
    {
      name: 'vmx-1-subnet' // index 0
      addressPrefix: '${ss_vnet_prefix}.8.0/27'
    }
    {
      name: 'vmx-2-subnet' // index 1
      addressPrefix: '${ss_vnet_prefix}.8.32/27'
    }
  ]
  tags: common_tags
}


param meraki_vmx_1_config = {
  vmName: '${scope_prefix}-meraki-vmx-1-${toLower(iac_env)}-${location}'
  merakiAuthToken: '5c28c8d031761beb656a3b2fa75dd1cf/923231dd521899a88d75da49a00120d7c7f9572a4030bba2539762c3242931c6084ddb7cbae0182970c77ee7a4a6779872aeefc7ed75dfec4ad03aa2ea85f17a/6e851a41b40cb4bbf13d1271271e687f008a08288958b9dfad2b2d29bb469e9b'
  virtualNetworkNewOrExisting: 'existing'
  virtualMachineSize: 'Standard_F4s_v2'
  applicationResourceName: 'vmx-1-meraki-managed-app'
}


param vmx_vhub_link_config = {
  name: 'vmx-vnet-vhub-link-${toLower(iac_env)}-${location}'
  targetVhub: {
    name: vmx_vhub_config.name
    rg: network_rg_config.name
  }
  routingConfiguration: {}
}



param meraki_vmx_2_config = {
  vmName: '${scope_prefix}-meraki-vmx-2-${toLower(iac_env)}-${location}'
  merakiAuthToken: 'e57677418eb20769255025d779518856/6b41f4ec201ea4299e18d1975e8427eb16767c065f2af9920c14ae89168719d98f39a9eaf72bf12338b404c156e74cde2b4f91534bfa084e72efbe25582e7758/475b13f7543572b0fb79b1381be225e0b7e506669822c24f6a784350071ad825'
  virtualNetworkNewOrExisting: 'existing'
  virtualMachineSize: 'Standard_F4s_v2'
  applicationResourceName: 'vmx-2-meraki-managed-app'
}



param frontdoor_rg_config = {
  name: '${scope_prefix}-frontdoor-rg-${toLower(iac_env)}-${location}'
  targetSubscriptionId: hub_subscriptionId
  tags: common_tags
  lock: 'CanNotDelete'
}

param frontdoor_config = {
  name: '${scope_prefix}-frontdoor-${toLower(iac_env)}'
  sku: 'Premium_AzureFrontDoor' // change with caution index in hub.bicep depends on the order of custom domains and afd endpoints to associate security policy.
  customDomains: [
    {
      name: 'maestro-dev'
      certificateType: 'ManagedCertificate'
      hostName: 'maestro-dev.globalmusicrights.com'
      azureDnsZoneResourceId: gmr_com_DNS_resourceId
    }
    {
      name: 'maestro-qa'
      certificateType: 'ManagedCertificate'
      hostName: 'maestro-qa.globalmusicrights.com'
      azureDnsZoneResourceId: gmr_com_DNS_resourceId
    }
    {
      name: 'maestro-prod'
      certificateType: 'ManagedCertificate'
      hostName: 'maestro.globalmusicrights.com'
      azureDnsZoneResourceId: gmr_com_DNS_resourceId
    }
    {
      name: 'concerto-dev'
      certificateType: 'ManagedCertificate'
      hostName: 'concerto-dev.iconicartistsgroup.com'
      azureDnsZoneResourceId: iag_com_DNS_resourceId
    }
    {
      name: 'concerto-qa'
      certificateType: 'ManagedCertificate'
      hostName: 'concerto-qa.iconicartistsgroup.com'
      azureDnsZoneResourceId: iag_com_DNS_resourceId
    }
    {
      name: 'concerto-prod'
      certificateType: 'ManagedCertificate'
      hostName: 'concerto.iconicartistsgroup.com'
      azureDnsZoneResourceId: iag_com_DNS_resourceId
    }
    {
      name: 'databricks-dev-gmr'
      certificateType: 'ManagedCertificate'
      hostName: 'databricks-dev.globalmusicrights.com'
      azureDnsZoneResourceId: gmr_com_DNS_resourceId
    }
    {
      name: 'databricks-qa-gmr'
      certificateType: 'ManagedCertificate'
      hostName: 'databricks-qa.globalmusicrights.com'
      azureDnsZoneResourceId: gmr_com_DNS_resourceId
    }
    {
      name: 'databricks-prod-gmr'
      certificateType: 'ManagedCertificate'
      hostName: 'databricks.globalmusicrights.com'
      azureDnsZoneResourceId: gmr_com_DNS_resourceId
    }
  ]
  originGroups: [
    {
      name: 'gmr-maestro-og-dev'
      origins: [
        {
          name: 'maestro-dev-primary'
          hostName:'stmaestrowebdev.z22.web.core.windows.net'
          priority: 1
          sharedPrivateLinkResource: {
            privateLink: { // resource ID of the storage account hosting the static website
              id: '/subscriptions/5dca793e-3f0d-4e8c-a1a6-dc5d84a5b5a2/resourceGroups/rg-maestro-dev/providers/Microsoft.Storage/storageAccounts/stmaestrowebdev'
            }
            groupId: 'web'
            privateLinkLocation: 'westus3'
            requestMessage: 'Azure FrontDoor private access the web storage account'
          }
        }
        // {
        //   name: 'maestro-dev-secondary'
        //   hostName:'stmaestrowebdev-secondary.z22.web.core.windows.net'
        //   priority: 2
        //   sharedPrivateLinkResource: {
        //     privateLink: { // resource ID of the storage account hosting the static website
        //       id: '/subscriptions/5dca793e-3f0d-4e8c-a1a6-dc5d84a5b5a2/resourceGroups/rg-maestro-dev/providers/Microsoft.Storage/storageAccounts/stmaestrowebdev'
        //     }
        //     groupId: 'web_secondary'
        //     privateLinkLocation: 'westus3'
        //     requestMessage: 'FrontDoor private access the web storage account'
        //   }
        // }
      ]
      loadBalancingSettings: {
        additionalLatencyInMilliseconds: 50
        sampleSize: 4
        successfulSamplesRequired: 3
      }
    }
    {
      name: 'gmr-maestro-og-qa'
      origins: [
        {
          name: 'maestro-qa-primary'
          hostName:'stmaestrowebqa.z22.web.core.windows.net'
          priority: 1
        }
        {
          name: 'maestro-qa-secondary'
          hostName:'stmaestrowebqa-secondary.z22.web.core.windows.net'
          priority: 2
        }
      ]
      loadBalancingSettings: {
        additionalLatencyInMilliseconds: 50
        sampleSize: 4
        successfulSamplesRequired: 3
      }
    }
    {
      name: 'gmr-maestro-og-prod'
      origins: [
        {
          name: 'maestro-prod-primary'
          hostName:'stmaestroweb.z22.web.core.windows.net'
          priority: 1
        }
        {
          name: 'maestro-prod-secondary'
          hostName:'stmaestroweb-secondary.z22.web.core.windows.net'
          priority: 2
        }
      ]
      loadBalancingSettings: {
        additionalLatencyInMilliseconds: 50
        sampleSize: 4
        successfulSamplesRequired: 3
      }
    }
    {
      name: 'iag-concerto-og-dev'
      origins: [
        {
          name: 'concerto-dev-primary'
          hostName:'iagstorconcertodevwus.z22.web.core.windows.net'
          priority: 1
          sharedPrivateLinkResource: {
            privateLink: { // resource ID of the storage account hosting the static website
              id: '/subscriptions/eac6d8b9-f610-4c94-9bbf-e69849f388cb/resourceGroups/iag-rg-concerto-dev-wus/providers/Microsoft.Storage/storageAccounts/iagstorconcertodevwus'
            }
            groupId: 'web'
            privateLinkLocation: 'westus3'
            requestMessage: 'Azure FrontDoor private access the web storage account'
          }
        }
        // {
        //   name: 'concerto-dev-secondary'
        //   hostName:'stconcertowebdev-secondary.z22.web.core.windows.net'
        //   priority: 2
        // }
      ]
      loadBalancingSettings: {
        additionalLatencyInMilliseconds: 50
        sampleSize: 4
        successfulSamplesRequired: 3
      }
    }
    {
      name: 'iag-concerto-og-qa'
      origins: [
        {
          name: 'concerto-qa-primary'
          hostName:'stconcertowebqa.z22.web.core.windows.net'
          priority: 1
        }
        {
          name: 'concerto-qa-secondary'
          hostName:'stconcertowebqa-secondary.z22.web.core.windows.net'
          priority: 2
        }
      ]
      loadBalancingSettings: {
        additionalLatencyInMilliseconds: 50
        sampleSize: 4
        successfulSamplesRequired: 3
      }
    }
    {
      name: 'iag-concerto-og-prod'
      origins: [
        {
          name: 'concerto-prod-primary'
          hostName:'iagstorconcertoprodwus.z22.web.core.windows.net'
          priority: 1
          sharedPrivateLinkResource: {
            privateLink: { // resource ID of the storage account hosting the static website
              id: '/subscriptions/fb7c9f2e-69ee-4891-a543-384e16123394/resourceGroups/iag-rg-concerto-prod-wus/providers/Microsoft.Storage/storageAccounts/iagstorconcertoprodwus'
            }
            groupId: 'web'
            privateLinkLocation: 'westus3'
            requestMessage: 'Azure FrontDoor private access the web storage account'
          }
        }
        // {
        //   name: 'concerto-prod-secondary'
        //   hostName:'stconcertoweb-secondary.z22.web.core.windows.net'
        //   priority: 2
        // }
      ]
      loadBalancingSettings: {
        additionalLatencyInMilliseconds: 50
        sampleSize: 4
        successfulSamplesRequired: 3
      }
    }
    {
      name: 'gmr-databricks-og-dev'
      origins: [
        {
          name: 'databricks-dev-primary'
          hostName:'adb-5564720177811041.1.azuredatabricks.net'
          priority: 1
        }
      ]
      loadBalancingSettings: {
        additionalLatencyInMilliseconds: 50
        sampleSize: 4
        successfulSamplesRequired: 3
      }
    }
    {
      name: 'gmr-databricks-og-qa'
      origins: [
        {
          name: 'databricks-qa-primary'
          hostName:'adb-956952623641079.19.azuredatabricks.net'
          priority: 1
        }
      ]
      loadBalancingSettings: {
        additionalLatencyInMilliseconds: 50
        sampleSize: 4
        successfulSamplesRequired: 3
      }
    }
    {
      name: 'gmr-databricks-og-prod'
      origins: [
        {
          name: 'databricks-prod-primary'
          hostName:'adb-3370497212488410.10.azuredatabricks.net'
          priority: 1
        }
      ]
      loadBalancingSettings: {
        additionalLatencyInMilliseconds: 50
        sampleSize: 4
        successfulSamplesRequired: 3
      }
    }
  ]
  afdEndpoints: [
    {
      name: 'gmr-maestro-afd-dev'
      routes:[
        {
        name: 'maestro-dev-route'
        customDomainName: 'maestro-dev'
        originGroupName: 'gmr-maestro-og-dev'
        }
      ]
    }
    {
      name: 'gmr-maestro-afd-qa'
      routes:[
        {
        name: 'maestro-qa-route'
        customDomainName: 'maestro-qa'
        originGroupName: 'gmr-maestro-og-qa'
        }
      ]
    }
    {
      name: 'gmr-maestro-afd-prod'
      routes:[
        {
        name: 'maestro-prod-route'
        customDomainName: 'maestro-prod'
        originGroupName: 'gmr-maestro-og-prod'
        }
      ]
    }
    {
      name: 'iag-concerto-afd-dev'
      routes:[
        {
        name: 'concerto-dev-route'
        customDomainName: 'concerto-dev'
        originGroupName: 'iag-concerto-og-dev'
        }
      ]
    }
    {
      name: 'iag-concerto-afd-qa'
      routes:[
        {
        name: 'concerto-qa-route'
        customDomainName: 'concerto-qa'
        originGroupName: 'iag-concerto-og-qa'
        }
      ]
    }
    {
      name: 'iag-concerto-afd-prod'
      routes:[
        {
        name: 'concerto-prod-route'
        customDomainName: 'concerto-prod'
        originGroupName: 'iag-concerto-og-prod'
        }
      ]
    }
    {
      name: 'gmr-databricks-afd-dev'
      routes:[
        {
        name: 'databricks-dev-route'
        customDomainName: 'databricks-dev-gmr'
        originGroupName: 'gmr-databricks-og-dev'
        }
      ]
    }
    {
      name: 'gmr-databricks-afd-qa'
      routes:[
        {
        name: 'databricks-qa-route'
        customDomainName: 'databricks-qa-gmr'
        originGroupName: 'gmr-databricks-og-qa'
        }
      ]
    }
    {
      name: 'gmr-databricks-afd-prod'
      routes:[
        {
        name: 'databricks-prod-route'
        customDomainName: 'databricks-prod-gmr'
        originGroupName: 'gmr-databricks-og-prod'
        }
      ]
    }
  ]
  originResponseTimeoutSeconds: 60
  securityPolicy: [
    {
       name: 'WAFPolicy'
    }
  ]
  tags: common_tags
}

param waf_config = {
  //name can only be alphanumeric like storage account name no - or _ .
  name: '${scope_prefix}waf${toLower(iac_env)}'
  managedRules: {
    managedRuleSets: [
      {
        ruleSetType: 'Microsoft_BotManagerRuleSet'
        ruleSetVersion: '1.0'
      }
    ]
  }
  policySettings: {
    mode: 'Prevention'
    redirectUrl: 'https://gmr.com'
  }
  sku: 'Premium_AzureFrontDoor'
  customRules: {
    rules: [
      {
        action: 'Redirect' 
        enabledState: 'Enabled'
        matchConditions: [
          {
            matchValue: [
              '40.118.224.61/32' //client portal VPN
              '20.245.150.64/32' // Internal iac_env Firewall in platform subscription
              '64.125.75.44/29' //  Ave Primary
              '174.34.80.52/29' //  Ave Secondary
            ]
            matchVariable: 'RemoteAddr'
            negateCondition: true
            operator: 'IPMatch'
            selector: null
            transforms: []
          }
        ]
        name: 'AllowOnlyVPNTraffic'
        priority: 1
        rateLimitDurationInMinutes: 1
        rateLimitThreshold: 10
        ruleType: 'MatchRule'
      }
    ]
  }
  tags: common_tags
}



param keyvault_rg_config = {
  name: '${scope_prefix}-keyvault-rg-${toLower(iac_env)}-${location}'
  targetSubscriptionId: hub_subscriptionId
  tags: common_tags
}

param keyvault_config = {
  name: '${scope_prefix}-kv-${toLower(iac_env)}-${location}'
  sku: 'Standard'
  tags: common_tags
}


param devops_vmss_rg_config = {
  name: '${scope_prefix}-devops-vmss-rg-${toLower(iac_env)}-${location}'
  targetSubscriptionId: hub_subscriptionId
  tags: common_tags
}

param private_dns_rg_config = {
  name: '${scope_prefix}-privatedns-rg-${toLower(iac_env)}-${location}'
  targetSubscriptionId: hub_subscriptionId
  tags: common_tags
  lock: 'CanNotDelete'
}

param dns_zone_configs = {
  tags: common_tags
  names: [
    'privatelink.blob.core.windows.net'
    'privatelink.dfs.core.windows.net'
    'privatelink.azuredatabricks.net'
    'privatelink.web.core.windows.net'
    'privatelink.azurewebsites.net'
    'privatelink.database.windows.net'
    'privatelink.file.core.windows.net'
    'privatelink.datafactory.azure.net'
    'privatelink.vaultcore.azure.net'
    'privatelink.azure-api.net'
  ]
  registrationEnabled: false
}






param dcr_rg_config = {
  name: '${scope_prefix}-dcr-rg-${toLower(iac_env)}-${location}'
  targetSubscriptionId: hub_subscriptionId
  tags: common_tags
}

param dcr_config = {
  name: 'microsoft-avdi-westus' // has to have this name to be picked up by the insights workbook for AVD
  dataFlows: [
    {
      streams: [
        'Microsoft-Perf'
        'Microsoft-Event'
      ]
      destinations: [
        'plf-log-sentinel-wu-01'
      ]
    }
  ]
  dataSources: {
    performanceCounters: [
      {
        streams: [
          'Microsoft-Perf'
        ]
        samplingFrequencyInSeconds: 30
        counterSpecifiers: [
          '\\LogicalDisk(C:)\\Avg. Disk Queue Length'
          '\\LogicalDisk(C:)\\Current Disk Queue Length'
          '\\Memory\\Available Mbytes'
          '\\Memory\\Page Faults/sec'
          '\\Memory\\Pages/sec'
          '\\Memory\\% Committed Bytes In Use'
          '\\PhysicalDisk(*)\\Avg. Disk Queue Length'
          '\\PhysicalDisk(*)\\Avg. Disk sec/Read'
          '\\PhysicalDisk(*)\\Avg. Disk sec/Transfer'
          '\\PhysicalDisk(*)\\Avg. Disk sec/Write'
          '\\Processor Information(_Total)\\% Processor Time'
          '\\User Input Delay per Process(*)\\Max Input Delay'
          '\\User Input Delay per Session(*)\\Max Input Delay'
          '\\RemoteFX Network(*)\\Current TCP RTT'
          '\\RemoteFX Network(*)\\Current UDP Bandwidth'
        ]
        name: 'perfCounterDataSource10'
      }
      {
        streams: [
          'Microsoft-Perf'
        ]
        samplingFrequencyInSeconds: 60
        counterSpecifiers: [
          '\\LogicalDisk(C:)\\% Free Space'
          '\\LogicalDisk(C:)\\Avg. Disk sec/Transfer'
          '\\Terminal Services(*)\\Active Sessions'
          '\\Terminal Services(*)\\Inactive Sessions'
          '\\Terminal Services(*)\\Total Sessions'
        ]
        name: 'perfCounterDataSource30'
      }
    ]
    windowsEventLogs: [
      {
        streams: [
          'Microsoft-Event'
        ]
        xPathQueries: [
          'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]'
          'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]'
          'System!*'
          'Microsoft-FSLogix-Apps/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]'
          'Application!*[System[(Level=2 or Level=3)]]'
          'Microsoft-FSLogix-Apps/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]'
        ]
        name: 'eventLogsDataSource'
      }
    ]
  }
  destinations:{
    logAnalytics: [
      {
        workspaceResourceId: logging_config.sentinelWorkspaceId
        name: 'plf-log-sentinel-wu-01'
      }
    ]
  }
  kind: 'Windows'
  tags: common_tags
}
