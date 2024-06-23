using '../definitions/gmr.bicep'


var resource_env = readEnvironmentVariable('resource_env', 'dev')
var iac_env = readEnvironmentVariable('iac_env', 'dev')
var scope_prefix = 'gmr'
var location = readEnvironmentVariable('location_suffix', 'wus')


var deployment_scopes = {
  dev: { // iac_env    
    dev: { // resource_env
      this_subscriptionId: 'c1d2e3f4-1234-5678-9abc-def012345678'
      hub_subscriptionId: 'd1e2f3g4-1234-5678-9abc-def012345678'
      vnet_prefix: '10.79'
    }
    qa: {
      this_subscriptionId: 'c1d2e3f4-1234-5678-9abc-def012345678'
      hub_subscriptionId: 'd1e2f3g4-1234-5678-9abc-def012345678'
      vnet_prefix: '10.78'
    }
    prod: {
      this_subscriptionId: 'c1d2e3f4-1234-5678-9abc-def012345678'
      hub_subscriptionId: 'd1e2f3g4-1234-5678-9abc-def012345678'
      vnet_prefix: '10.20'
    }
  }
  prod: {
    dev: {
      this_subscriptionId: 'i1j2k3l4-1234-5678-9abc-def012345678'
      hub_subscriptionId: 'b1c2d3e4-5678-9abc-def0-123456789abc'
      vnet_prefix: '10.79'
    }
    qa: {
      this_subscriptionId: 'j1k2l3m4-1234-5678-9abc-def012345678'
      hub_subscriptionId: 'b1c2d3e4-5678-9abc-def0-123456789abc'
      vnet_prefix: '10.78'
    }
    prod: {
      this_subscriptionId: 'k1l2m3n4-5678-9abc-def0-123456789abc'
      hub_subscriptionId: 'b1c2d3e4-5678-9abc-def0-123456789abc'
      vnet_prefix: '10.20'
    }
  }
  drdev: {
    dev: {
      this_subscriptionId: 'e1f2g3h4-1234-5678-9abc-def012345678'
      hub_subscriptionId: 'f1g2h3i4-1234-5678-9abc-def012345678'
      vnet_prefix: '10.179'
    }
    qa: {
      this_subscriptionId: 'e1f2g3h4-1234-5678-9abc-def012345678'
      hub_subscriptionId: 'f1g2h3i4-1234-5678-9abc-def012345678'
      vnet_prefix: '10.178'
    }
    prod: {
      this_subscriptionId: 'e1f2g3h4-1234-5678-9abc-def012345678'
      hub_subscriptionId: 'f1g2h3i4-1234-5678-9abc-def012345678'
      vnet_prefix: '10.120'
    }
  }
  drprod: {
    dev: {
      this_subscriptionId: 'l1m2n3o4-5678-9abc-def0-123456789abc'
      hub_subscriptionId: 'h1i2j3k4-5678-9abc-def0-123456789abc'
      vnet_prefix: '10.179'
    }
    qa: {
      this_subscriptionId: 'm1n2o3p4-5678-9abc-def0-123456789abc'
      hub_subscriptionId: 'h1i2j3k4-5678-9abc-def0-123456789abc'
      vnet_prefix: '10.178'
    }
    prod: {
      this_subscriptionId: 'n1o2p3q4-5678-9abc-def0-123456789abc'
      hub_subscriptionId: 'h1i2j3k4-5678-9abc-def0-123456789abc'
      vnet_prefix: '10.120'
    }
  }
}


var currentEnvironment = deployment_scopes [toLower(iac_env)][toLower(resource_env)]
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
      name: 'subnet-funcapp-maestro-${toLower(resource_env)}'
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
    {
      name: 'subnet-vnet-data-gw-powerbi-${toLower(resource_env)}'
      addressPrefix: '${vnet_prefix}.5.32/27'
      delegations: [
        {
          name: 'Microsoft.PowerPlatform/vnetaccesslinks'
          properties: {
            serviceName: 'Microsoft.PowerPlatform/vnetaccesslinks'
          }
        }
      ]
      serviceEndpoints:[
        {service: 'Microsoft.Storage.Global'}
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
    // new rules for the new Databricks control plane traffic as per email from MSFT on 3/7/2024
    {
      name: 'AllowAzureDatabricks-ControlPlane'
      properties: {
        priority: 104 
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRanges: ['8443-8451'] // Port range for new Databricks control plane traffic
        sourceAddressPrefix: 'VirtualNetwork'
        destinationAddressPrefix: 'AzureDatabricks' // Adjust if there's a specific address prefix; use '*' if unsure
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
