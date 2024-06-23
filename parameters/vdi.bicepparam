using '../definitions/vdi.bicep'

var resource_env = readEnvironmentVariable('resource_env', 'iag')
var iac_env = readEnvironmentVariable('iac_env', 'dev')

var location = readEnvironmentVariable('location_suffix', 'wus')

var deployment_scopes = {
  dev: { // iac env 
    iag: { // resource env
      this_subscriptionId: 'c1d2e3f4-1234-5678-9abc-def012345678' // platform dev spokes
      hub_subscriptionId: 'd1e2f3g4-1234-5678-9abc-def012345678' // platform dev hub
      vnet_prefix: '10.30'
    }
    gmr: {
      this_subscriptionId: 'c1d2e3f4-1234-5678-9abc-def012345678' // platform dev spokes
      hub_subscriptionId: 'd1e2f3g4-1234-5678-9abc-def012345678' // platform dev hub
      vnet_prefix: '10.20'
    }
  }
  prod:{
    iag: {
      this_subscriptionId: 'u1v2w3x4-5678-9abc-def0-123456789abc' 
      hub_subscriptionId: 'b1c2d3e4-5678-9abc-def0-123456789abc' 
      vnet_prefix: '10.30'
    }
    gmr: {
      this_subscriptionId: 'v1w2x3y4-5678-9abc-def0-123456789abc' 
      hub_subscriptionId: 'b1c2d3e4-5678-9abc-def0-123456789abc' 
      vnet_prefix: '10.20'
    }
  }
  drdev: {
    iag: {
      this_subscriptionId: 'e1f2g3h4-1234-5678-9abc-def012345678' 
      hub_subscriptionId: 'f1g2h3i4-1234-5678-9abc-def012345678' 
      vnet_prefix: '10.130'
    }
    gmr: {
      this_subscriptionId: 'e1f2g3h4-1234-5678-9abc-def012345678' 
      hub_subscriptionId: 'f1g2h3i4-1234-5678-9abc-def012345678' 
      vnet_prefix: '10.120'
    }
  }
  drprod: {
    iag: {
      this_subscriptionId: 'w1x2y3z4-5678-9abc-def0-123456789abc' 
      hub_subscriptionId: 'h1i2j3k4-5678-9abc-def0-123456789abc' 
      vnet_prefix: '10.130'
    }
    gmr: {
      this_subscriptionId: 'x1y2z3a4-5678-9abc-def0-123456789abc' 
      hub_subscriptionId: 'h1i2j3k4-5678-9abc-def0-123456789abc' 
      vnet_prefix: '10.120'
    }
  }
}

var currentEnvironment = deployment_scopes [toLower(iac_env)] [toLower(resource_env)]
var this_subscriptionId = currentEnvironment.this_subscriptionId
var hub_subscriptionId = currentEnvironment.hub_subscriptionId
var hub_name = 'platform-vhub-${iac_env}-${location}'
var hub_rg = 'platform-network-rg-${iac_env}-${location}'
var fw_name = 'platform-fw-${iac_env}-${location}'
var vdi_vnet_prefix = currentEnvironment.vnet_prefix
var scope_prefix = '${resource_env}-vdi'

param logging_config = {
  sentinelWorkspaceId: '/subscriptions/b1c2d3e4-5678-9abc-def0-123456789abc/resourcegroups/plf-rg-sentinel-wu-01/providers/microsoft.operationalinsights/workspaces/plf-log-sentinel-wu-01'
}

param hub_fw_config = {
  name: fw_name
  rgName: hub_rg
  subId: hub_subscriptionId
}

var common_tags = {
  CreatedBy: 'Bicep'
  Environment: iac_env
  //DeployedBy: 'iac_${iac_env}'
}

param network_rg_config  = {
  name: '${scope_prefix}-network-rg-${toLower(iac_env)}-${location}'
  targetSubscriptionId: this_subscriptionId
  tags: common_tags
}

param vdi_vnet_config  = {
  name: '${scope_prefix}-vnet-${toLower(iac_env)}-${location}'
  addressSpace: '${vdi_vnet_prefix}.224.0/20'
  flowTimeoutInMinutes: 20
  subnetConfigs: [
    {
      name: 'subnet-default-${toLower(iac_env)}'
      addressPrefix: '${vdi_vnet_prefix}.224.0/25'
    }
    {
      name: 'subnet-vdi-${toLower(iac_env)}'
      addressPrefix: '${vdi_vnet_prefix}.224.128/25'
    }
  ]
  tags: common_tags
}

param vhub_link_config = {
  name: '${scope_prefix}-vnet-vhub-link-${toLower(iac_env)}-${location}'
  targetVhub: {
    name: hub_name
    rg: hub_rg
    subId: hub_subscriptionId
  }
  routingConfiguration: {}
}

param network_auxiliary_rg_config  = {
  name: '${scope_prefix}-network-auxiliary-${toLower(iac_env)}-${location}'
  targetSubscriptionId: this_subscriptionId
  tags: common_tags
}


param vdi_rg_config = {
  name: '${scope_prefix}-rg-${toLower(iac_env)}-${location}'
  targetSubscriptionId: this_subscriptionId
  tags: common_tags
}

param vdi_hostpool_config = {
  name: '${scope_prefix}-hostpool-${toLower(iac_env)}-${location}'
  friendlyName: '${scope_prefix}-hostpool-${toLower(iac_env)}-${location}'
  type: 'Personal'
  personalDesktopAssignmentType: 'Direct'
  customRdpProperty: 'audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;screen mode id:i:2;'
  agentUpdateType: 'Default'
  agentUpdateMaintenanceWindowTimeZone: 'Pacific Standard Time'
  tags: common_tags
}

param vdi_appgroup_config = {
  name: '${scope_prefix}-appgroup-${toLower(iac_env)}-${location}'
  friendlyName: '${scope_prefix}-appgroup-${toLower(iac_env)}-${location}'
  applicationGroupType: 'Desktop'
  tags: common_tags
}

param vdi_workspace_config = {
  name: '${scope_prefix}-workspace-${toLower(iac_env)}-${location}'
  friendlyName: '${scope_prefix}-workspace-${toLower(iac_env)}-${location}'
  tags: common_tags
}



