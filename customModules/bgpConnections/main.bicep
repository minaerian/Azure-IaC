// Metadata for the module
metadata name = 'Virtual Hub BGP Connections'
metadata description = '''This module deploys a BGP Connection to a Virtual Hub.
It establishes a BGP peering connection between the Virtual Hub and an external entity.'''
metadata owner = 'Azure/module-maintainers'

@description('Required. The name of the BGP Connection.')
param name string

@description('Required. Resource ID of the HubVirtualNetworkConnection.')
param hubVirtualNetworkConnectionId string

@description('Required. Peer ASN.')
param peerAsn int

@description('Required. Peer IP.')
param peerIp string

// params to refrance the virtual hub
param vhubName string


resource vhub 'Microsoft.Network/virtualHubs@2023-04-01' existing = {
  name: vhubName
}


// Main resource deployment for the BGP Connection
resource bgpConnection 'Microsoft.Network/virtualHubs/bgpConnections@2023-04-01' = {
  name: name
  parent: vhub
  properties: {
    hubVirtualNetworkConnection: {
      id: hubVirtualNetworkConnectionId
    }
    peerAsn: peerAsn
    peerIp: peerIp
  }
}

// Outputs
@description('The resource ID of the BGP Connection.')
output resourceId string = bgpConnection.id

@description('The name of the BGP Connection.')
output connectionName string = bgpConnection.name

// Note: Add any additional outputs you find necessary based on the deployment context
