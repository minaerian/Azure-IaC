using '../definitions/iag.bicep'


var resource_env = readEnvironmentVariable('resource_env', 'dev')
var iac_env = readEnvironmentVariable('iac_env', 'dev')
var scope_prefix = 'iag'
var location = readEnvironmentVariable('location_suffix', 'wus')



var deployment_scopes = {
  dev: { // iac env 
    dev: { // resource env
      this_subscriptionId: 'c1d2e3f4-1234-5678-9abc-def012345678' // platform dev spokes
      hub_subscriptionId: 'd1e2f3g4-1234-5678-9abc-def012345678' // platform dev hub
      vnet_prefix: '10.72'
    }
    qa: { // resource env
      this_subscriptionId: 'c1d2e3f4-1234-5678-9abc-def012345678' // platform qa spokes
      hub_subscriptionId: 'd1e2f3g4-1234-5678-9abc-def012345678' // platform qa hub
      vnet_prefix: '10.73'
    }
    prod: { // resource env
      this_subscriptionId: 'c1d2e3f4-1234-5678-9abc-def012345678' // platform prod spokes
      hub_subscriptionId: 'd1e2f3g4-1234-5678-9abc-def012345678' // platform prod hub
      vnet_prefix: '10.30'
    }
  }
  prod: {
    dev: {
      this_subscriptionId: 'o1p2q3r4-5678-9abc-def0-123456789abc' 
      hub_subscriptionId: 'b1c2d3e4-5678-9abc-def0-123456789abc'
      vnet_prefix: '10.72'
    }
    qa: {
      this_subscriptionId: 'p1q2r3s4-5678-9abc-def0-123456789abc' 
      hub_subscriptionId: 'b1c2d3e4-5678-9abc-def0-123456789abc'
      vnet_prefix: '10.73'
    }
    prod: {
      this_subscriptionId: 'q1r2s3t4-5678-9abc-def0-123456789abc' 
      hub_subscriptionId: 'b1c2d3e4-5678-9abc-def0-123456789abc'
      vnet_prefix: '10.30'
    }
  }
  drdev: {
    dev: {
      this_subscriptionId: 'e1f2g3h4-1234-5678-9abc-def012345678'
      hub_subscriptionId: 'f1g2h3i4-1234-5678-9abc-def012345678'
      vnet_prefix: '10.172'
    }
    qa: {
      this_subscriptionId: 'e1f2g3h4-1234-5678-9abc-def012345678'
      hub_subscriptionId: 'f1g2h3i4-1234-5678-9abc-def012345678'
      vnet_prefix: '10.173'
    }
    prod: {
      this_subscriptionId: 'e1f2g3h4-1234-5678-9abc-def012345678'
      hub_subscriptionId: 'f1g2h3i4-1234-5678-9abc-def012345678'
      vnet_prefix: '10.130'
    }
  }
  drprod: {
    dev: {
      this_subscriptionId: 'r1s2t3u4-5678-9abc-def0-123456789abc'
      hub_subscriptionId: 'h1i2j3k4-5678-9abc-def0-123456789abc'
      vnet_prefix: '10.172'
    }
    qa: {
      this_subscriptionId: 's1t2u3v4-5678-9abc-def0-123456789abc'
      hub_subscriptionId: 'h1i2j3k4-5678-9abc-def0-123456789abc'
      vnet_prefix: '10.173'
    }
    prod: {
      this_subscriptionId: 't1u2v3w4-5678-9abc-def0-123456789abc'
      hub_subscriptionId: 'h1i2j3k4-5678-9abc-def0-123456789abc'
      vnet_prefix: '10.130'
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

var databricksNsgResourceId  = '/subscriptions/${this_subscriptionId}/resourceGroups/${network_auxiliary_config.name}/providers/Microsoft.Network/networkSecurityGroups/${databricks_nsg_config.name}'
var databricksUdrResourceId = '/subscriptions/${this_subscriptionId}/resourceGroups/${network_auxiliary_config.name}/providers/Microsoft.Network/routeTables/${databricks_udr_config.name}'



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
  }
}

param vnet_config = {
  name: '${scope_prefix}-vnet-${toLower(resource_env)}-${location}'
  addressSpace: '${vnet_prefix}.0.0/20'
  flowTimeoutInMinutes: 20
  subnetConfigs: [
    {
      name: 'subnet-databricks-public-${toLower(resource_env)}'
      addressPrefix: '${vnet_prefix}.0.0/23'
      delegations: [
        {
          name: 'databricks'
          properties: {
            serviceName: 'Microsoft.Databricks/workspaces'
          }
        }
      ]
      networkSecurityGroupId: databricksNsgResourceId
      routeTableId: databricksUdrResourceId
    }
    {
      name: 'subnet-databricks-private-${toLower(resource_env)}'
      addressPrefix: '${vnet_prefix}.2.0/23'
      delegations: [
        {
          name: 'databricks'
          properties: {
            serviceName: 'Microsoft.Databricks/workspaces'
          }
        }
      ]
      networkSecurityGroupId: databricksNsgResourceId
      routeTableId: databricksUdrResourceId
    }
    {
      name: 'subnet-default-${toLower(resource_env)}'
      addressPrefix: '${vnet_prefix}.4.0/25'
    }
    {
      name: 'subnet-private-endpoint-${toLower(resource_env)}'
      addressPrefix: '${vnet_prefix}.4.128/25'
      serviceEndpoints: [
        {service: 'Microsoft.Storage.Global'}
      ]
    }
    {
      name: 'subnet-funcapp-${toLower(resource_env)}'
      addressPrefix: '${vnet_prefix}.5.0/27'
      delegations: [
        {
          name: 'Microsoft.Web/serverFarms'
          properties: {
          serviceName: 'Microsoft.Web/serverFarms'
          }
        }
      ]
      serviceEndpoints:[
        {service: 'Microsoft.Web'}
        {service: 'Microsoft.Sql'}
        {service: 'Microsoft.Storage.Global'}
        {service: 'Microsoft.KeyVault'}
        {service: 'Microsoft.AzureActiveDirectory'}
        {service: 'Microsoft.Cognitiveservices'}
      ]
    }
  ]
  tags: {
    CreatedBy: 'Bicep'
    Environment: resource_env
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
  }
}

param databricks_nsg_config = {
  name: '${scope_prefix}-databricks-nsg-${toLower(resource_env)}-${location}'
  securityRules: [
    {
      name: 'AllowAAD-transit'
      properties: {
        priority: 200
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '443'
        sourceAddressPrefix: 'VirtualNetwork'
        destinationAddressPrefix: 'AzureActiveDirectory'
      }
    }
    {
      name: 'AllowAzureFrontDoor-transit'
      properties: {
        priority: 201
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '443'
        sourceAddressPrefix: 'VirtualNetwork'
        destinationAddressPrefix: 'AzureFrontDoor.Frontend'
      }
    }
    {
      name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound'
      properties: {
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: '*'
        sourcePortRange: '*'
        destinationPortRange: '*'
        sourceAddressPrefix: 'VirtualNetwork'
        destinationAddressPrefix: 'VirtualNetwork'
      }
    }
    {
      name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-outbound'
      properties: {
        priority: 100
        direction: 'Outbound'
        access: 'Allow'
        protocol: '*'
        sourcePortRange: '*'
        destinationPortRange: '*'
        sourceAddressPrefix: 'VirtualNetwork'
        destinationAddressPrefix: 'VirtualNetwork'
      }
    }
    {
      name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql'
      properties: {
        priority: 101
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '3306'
        sourceAddressPrefix: 'VirtualNetwork'
        destinationAddressPrefix: 'Sql'
      }
    }
    {
      name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage'
      properties: {
        priority: 102
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '443'
        sourceAddressPrefix: 'VirtualNetwork'
        destinationAddressPrefix: 'Storage'
      }
    }
    {
      name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub'
      properties: {
        priority: 103
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '9093'
        sourceAddressPrefix: 'VirtualNetwork'
        destinationAddressPrefix: 'EventHub'
      }
    }
  ]
  tags: {
    CreatedBy: 'Bicep'
    Environment: resource_env
  }
}

//
param databricks_udr_config = {
  name: '${scope_prefix}-databricks-udr-${toLower(resource_env)}-${location}'
  routes:  [
    {
      name: 'adb-extinfra'
      properties: {
        addressPrefix: '13.91.84.96/28'
        nextHopType: 'Internet'
      }
    }
    {
      name: 'adb-servicetag'
      properties: {
        addressPrefix: 'AzureDatabricks'
        nextHopType: 'Internet'
      }
    }
    {
      name: 'adb-eventhubtag'
      properties: {
        addressPrefix: 'EventHub'
        nextHopType: 'Internet'
      }
    }
    {
      name: 'adb-sqltag'
      properties: {
        addressPrefix: 'Sql'
        nextHopType: 'Internet'
      }
    }
    {
      name: 'adb-storagetag'
      properties: {
        addressPrefix: 'Storage'
        nextHopType: 'Internet'
      }
    }
  ]
  tags: {
    CreatedBy: 'Bicep'
    Environment: resource_env
  }
}
