@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. This is the name of the your VM')
@metadata({ title: 'VM Name' })
param vmName string

@description('This is your authentication string generated by Meraki Dashboard')
param merakiAuthToken string

@description('Availability zone number for the vMX')
@allowed([
  '0'
  '1'
  '2'
  '3'
])
param zone string = '0'

@description('New or Existing VNet Name')
param virtualNetworkName string

@description('Boolean indicating whether the VNet is new or existing')
param virtualNetworkNewOrExisting string

@description('VNet address prefix')
param virtualNetworkAddressPrefix string

@description('Resource group of the VNet')
param virtualNetworkResourceGroup string

@description('The size of the VM')
param virtualMachineSize string

@description('New or Existing subnet Name')
param subnetName string

@description('Subnet address prefix')
param subnetAddressPrefix string

@description('The name of the application resource')
param applicationResourceName string = '' //'Meraki-vMX-Managed-Application'

@description('The managed resource group id')
param managedResourceGroupId string = ''

@description('The managed identity')
param managedIdentity object = {}

//var managedResourceGroupId_var = (empty(managedResourceGroupId) ? '${subscription().id}/resourceGroups/${take('${resourceGroup().name}-${uniqueString(resourceGroup().id)}${uniqueString(applicationResourceName)}', 90)}' : managedResourceGroupId)

var managedResourceGroupId_var = empty(managedResourceGroupId) ? '${subscription().id}/resourceGroups/${take('${vmName}-${uniqueString(resourceGroup().id)}${uniqueString(applicationResourceName)}', 90)}' : managedResourceGroupId


resource applicationResource 'Microsoft.Solutions/applications@2017-09-01' = {
  location: resourceGroup().location
  kind: 'MarketPlace'
  name: applicationResourceName
  plan: {
    name: 'cisco-meraki-vmx'
    product: 'cisco-meraki-vmx'
    publisher: 'cisco'
    version: '15.37.4'
  }
  identity: (empty(managedIdentity) ? json('null') : managedIdentity)
  properties: {
    managedResourceGroupId: managedResourceGroupId_var
    parameters: {
      location: {
        value: location
      }
      vmName: {
        value: vmName
      }
      merakiAuthToken: {
        value: merakiAuthToken
      }
      zone: {
        value: zone
      }
      virtualNetworkName: {
        value: virtualNetworkName
      }
      virtualNetworkNewOrExisting: {
        value: virtualNetworkNewOrExisting
      }
      virtualNetworkAddressPrefix: {
        value: virtualNetworkAddressPrefix
      }
      virtualNetworkResourceGroup: {
        value: virtualNetworkResourceGroup
      }
      virtualMachineSize: {
        value: virtualMachineSize
      }
      subnetName: {
        value: subnetName
      }
      subnetAddressPrefix: {
        value: subnetAddressPrefix
      }
    }
    jitAccessPolicy: null
  }
}

output applicationResourceId string = applicationResource.id
output subnetaddressPrefix string = subnetAddressPrefix