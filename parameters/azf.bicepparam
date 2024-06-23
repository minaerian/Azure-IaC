using '../definitions/azf.bicep'

var resource_env = readEnvironmentVariable('resource_env', 'prod')
var iac_env = readEnvironmentVariable('iac_env', 'dev')
var scope_prefix = 'azf'
var location = readEnvironmentVariable('location_suffix', 'wus')


var deployment_scopes = {
  dev: { // iac env 
    prod: { // resource env
      this_subscriptionId: 'c1d2e3f4-1234-5678-9abc-def012345678' // platform dev spokes
      hub_subscriptionId: 'd1e2f3g4-1234-5678-9abc-def012345678' // platform dev hub
      vnet_prefix: '10.50'
    }
  }
  prod: {
    prod: {
      this_subscriptionId: 'a1b2c3d4-5678-9abc-def0-123456789abc' 
      hub_subscriptionId: 'b1c2d3e4-5678-9abc-def0-123456789abc' 
      vnet_prefix: '10.50'
    }
  }
  drdev: {
    prod: {
      this_subscriptionId: 'e1f2g3h4-1234-5678-9abc-def012345678' 
      hub_subscriptionId: 'f1g2h3i4-1234-5678-9abc-def012345678' 
      vnet_prefix: '10.150'
    }
  }
  drprod: {
    prod: {
      this_subscriptionId: 'g1h2i3j4-5678-9abc-def0-123456789abc' 
      hub_subscriptionId: 'h1i2j3k4-5678-9abc-def0-123456789abc' 
      vnet_prefix: '10.150'
    }
  }
}


var currentEnvironment = deployment_scopes [toLower(iac_env)] [toLower(resource_env)]
var this_subscriptionId = currentEnvironment.this_subscriptionId
var hub_subscriptionId = currentEnvironment.hub_subscriptionId
var hub_name = 'platform-vhub-${iac_env}-${location}'
var hub_rg = 'platform-network-rg-${iac_env}-${location}'
var fw_name = 'platform-fw-${iac_env}-${location}'
var vnet_prefix = currentEnvironment.vnet_prefix

param hub_fw_config = {
  name: fw_name
  rgName: hub_rg
  subId: hub_subscriptionId
}

param network_rg_config = {
  name: '${scope_prefix}-network-rg-${toLower(resource_env)}-${location}'
  targetSubscriptionId: this_subscriptionId
  tags: {
    CreatedBy: 'Bicep'
    Environment: resource_env
    Accounting: scope_prefix
  }
}

param vnet_config = {
  name: '${scope_prefix}-vnet-${toLower(resource_env)}-${location}'
  addressSpace: '${vnet_prefix}.0.0/20'
  flowTimeoutInMinutes: 20
  subnetConfigs: [
    {
      name: 'subnet-default-${toLower(resource_env)}'
      addressPrefix: '${vnet_prefix}.4.0/25'
    }
    {
      name: 'subnet-private-endpoint-${toLower(resource_env)}'
      addressPrefix: '${vnet_prefix}.4.128/25'
    }
  ]
  tags: {
    CreatedBy: 'Bicep'
    Environment: resource_env
    Accounting: scope_prefix
  }
}

param vhub_link_config = {
  name: '${scope_prefix}-vnet-vhub-link-${toLower(resource_env)}-${location}'
  targetVhub: {
    name: hub_name
    rg: hub_rg
    subId: hub_subscriptionId
  }
  routingConfiguration: {}
}

param network_auxiliary_config = {
  name: '${scope_prefix}-network-auxiliary-${toLower(resource_env)}-${location}'
  targetSubscriptionId: this_subscriptionId
  tags: {
    CreatedBy: 'Bicep'
    Environment: resource_env
    Accounting: scope_prefix
  }
}

param business_apps_rg_config = {
  name: '${scope_prefix}-business-apps-rg-${toLower(resource_env)}-${location}'
  targetSubscriptionId: this_subscriptionId
  tags: {
    CreatedBy: 'Bicep'
    Environment: resource_env
    Accounting: scope_prefix
  }
}

