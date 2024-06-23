param name string

param location string = resourceGroup().location

@description('Required. The name of the "peered" VPN Gateway.')
param peer object

@description('Required. The Resource Id of the source virtual hub.')
param vhubName string

@description('Optional, sensible default.')
param vpnGatewayScaleUnits int = 2

@description('Optional. VPN Site Properties')
param site_linkProperties object = {
  linkProviderName: 'Azure'
  linkSpeedInMbps: 500
}

@description('Required. The name of the connection between the two Gateways.')
param vpnConnection_name string

@description('Required. The pre-shared key for the connection.')
param vpnConnection_linkPsk string

@description('Optional, sensible defaults')
param vpnConnection_linkProperties object = {
  connectionBandwidth: 10
  enableBgp: true
  enableRateLimiting: false
  sharedKey: vpnConnection_linkPsk
  useLocalAzureIpAddress: false
  usePolicyBasedTrafficSelectors: false
  vpnConnectionProtocolType: 'IKEv2'
  vpnLinkConnectionMode: 'Default'
}

@description('Optional, sensible default.')
param enableInternetSecurity bool = false

@description('Optional, resource tags.')
param tags object = {}

// REFERENCE EXISTING RESOURCES

resource vhub 'Microsoft.Network/virtualHubs@2023-04-01' existing = {
  name: vhubName
}

resource dest_vnetGateway 'Microsoft.Network/virtualNetworkGateways@2023-04-01' existing = {
  name: peer.name
  scope: resourceGroup(peer.subId, peer.rgName)
}

resource dest_vnetGateway_pip 'Microsoft.Network/publicIPAddresses@2023-04-01' existing = {
  name: peer.gwIpName
  scope: resourceGroup(peer.subId, peer.rgName)
}

// BEGIN RESOURCE CREATION

resource source_s2sGateway 'Microsoft.Network/vpnGateways@2022-01-01' = {
  name: name
  location: location
  properties: {
    virtualHub: { id: vhub.id }
    bgpSettings: { asn: vhub.properties.virtualRouterAsn }
    vpnGatewayScaleUnit: vpnGatewayScaleUnits
  }
}

resource vpnsite 'Microsoft.Network/vpnSites@2022-01-01' = {
  name: name
  location: location
  tags: tags
  dependsOn: [ source_s2sGateway ]
  properties: {
    virtualWan: {
      id: vhub.properties.virtualWan.id
    }
    vpnSiteLinks: [
      {
        name: dest_vnetGateway.name
        properties: {
          bgpProperties: {
            asn: dest_vnetGateway.properties.bgpSettings.asn
            bgpPeeringAddress: dest_vnetGateway.properties.bgpSettings.bgpPeeringAddress
          }
          ipAddress: dest_vnetGateway_pip.properties.ipAddress // reference the IP Address of the destination FW here, maybe another 'existing' reference
          linkProperties: site_linkProperties
        }
      }
    ]
  }
}

resource vpnConnection 'Microsoft.Network/vpnGateways/vpnConnections@2023-04-01' = {
  parent: source_s2sGateway
  name: vpnConnection_name
  properties: {
    enableInternetSecurity: enableInternetSecurity
    remoteVpnSite: {
      id: vpnsite.id
    }
    routingConfiguration: {
      associatedRouteTable: {
        id: '${vhub.id}/hubRouteTables/defaultRouteTable'
      }
      propagatedRouteTables: {
        ids: [
          {
            id: '${vhub.id}/hubRouteTables/noneRouteTable'
          }
        ]
        labels: [ 'none' ]
      }
    }
    vpnLinkConnections: [
      {
        name: '${name}-${peer.name}-link'
        properties: union(
          vpnConnection_linkProperties, 
          {
            vpnSiteLink: {
              id: vpnsite.properties.vpnSiteLinks[0].id
            }
          }
        )
      }
    ]
  }
}


@description('The IP Address of the BGP Peer on the s2s GW.')
output bgpPeeringAddress string = source_s2sGateway.properties.bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0]
@description('The IP Address of the s2s GW.')
output gatewayPublicIpAddress string = source_s2sGateway.properties.ipConfigurations[0].publicIpAddress
@description('The ASN of the s2s GW.')
output vpnGatewayAsn int = source_s2sGateway.properties.bgpSettings.asn

