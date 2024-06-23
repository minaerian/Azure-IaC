// VPN Gateway Parameters
@description('Required. The p2sVpn Gateway Name.')
param name string

// This is unused for the moment because the DNS servers are referenced from the Firewall
// @description('Optional. Custom DNS Servers.')
// param customDnsServers array = []

@description('Optional. Routing Preference Internet.')
param isRoutingPreferenceInternet bool = false

@description('Optional. Virtual Hub ID.')
param virtualHubId string

@description('Optional. VPN Gateway Scale Unit.')
param vpnGatewayScaleUnit int = 1

@description('Optional. Enable Internet Security.')
param enableInternetSecurity bool = true

@description('Optional. Name of the P2S Connection.')
param p2sConnectionName string = '${name}-connection'

@description('VPN Client IP Address.')
param vpnClientIPAddress string = ''

// VPN Gateway Config Parameters
@description('Optional. The p2sVpn Gateway Config name')
param gatewayConfigName string = '${name}-config'

@description('Optional. The AAD Audience.')
param aadParams object

@allowed([
  'OpenVPN'
  'IkeV2'
])
param vpnProtocols string = 'OpenVPN'

@allowed([
  'AAD'
  'Certificate'
  'Radius'
])
param vpnAuthenticationTypes string = 'AAD'

// Shared Parameters
@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Tags for the resource.')
param tags object

// Parameters required to reference the existing Firewall
param fwName string
param fwResourceGroup string
param fwSubscriptionId string

resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-04-01' existing = {//existing resource as a workaround for CARML bug
  name: fwName
  scope: resourceGroup(fwSubscriptionId, fwResourceGroup)
}

resource p2sVpnGatewayConfig 'Microsoft.Network/vpnServerConfigurations@2023-04-01' = {
  name: gatewayConfigName
  location: location
  properties: {
    vpnProtocols: [ vpnProtocols ]
    vpnAuthenticationTypes: [ vpnAuthenticationTypes ]
    aadAuthenticationParameters: aadParams
  }
}

resource p2sVpnGateway 'Microsoft.Network/p2svpnGateways@2023-04-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    customDnsServers: [ azureFirewall.properties.hubIPAddresses.privateIPAddress ] // reference to existing resource as a workaround for CARML bug
    isRoutingPreferenceInternet: isRoutingPreferenceInternet
    p2SConnectionConfigurations: [{
      id: p2sVpnGatewayConfig.id
      name: p2sConnectionName
      properties: {
        enableInternetSecurity: enableInternetSecurity
        vpnClientAddressPool: {
          addressPrefixes: [
            vpnClientIPAddress
          ]
        }
      }
    }]
    virtualHub: {
      id: virtualHubId
    }
    vpnGatewayScaleUnit: vpnGatewayScaleUnit
    vpnServerConfiguration: {
      id: p2sVpnGatewayConfig.id
    }
  }
}

output p2sVpnGatewayConfigId string = p2sVpnGatewayConfig.id

output p2sVpnGatewayId string = p2sVpnGateway.id
