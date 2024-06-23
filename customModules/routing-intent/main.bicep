param name string = ''
param routingIntentDestinations array = []
param routingPolicyName string = ''
param routingIntentNextHop string = ''
@description('Conditional. The name of the parent virtual hub. Required if the template is used in a standalone deployment.')
param virtualHubName string
param internetTrafficRoutingPolicy bool
param privateTrafficRoutingPolicy bool
// NOTE: Routing Intent requires either InternetTrafficRoutingPolicy or PrivateTrafficRoutingPolicy to be true, otherwise feature will be disabled.

resource virtualHub 'Microsoft.Network/virtualHubs@2022-11-01' existing = {
  name: virtualHubName
}

resource virtualWanRoutingIntent 'Microsoft.Network/virtualHubs/routingIntent@2023-04-01' = {
  name: '${name}-RoutingIntent'
  parent: virtualHub
  properties: {
    routingPolicies: (internetTrafficRoutingPolicy && privateTrafficRoutingPolicy) ? [
        {
          name: 'PublicTraffic'
          destinations: ['Internet']
          nextHop: routingIntentNextHop
        }
        {
          name: 'PrivateTraffic'
          destinations: ['PrivateTraffic']
          nextHop: routingIntentNextHop
        }
      ] : (internetTrafficRoutingPolicy && !privateTrafficRoutingPolicy) ? [
        {
          name: 'PublicTraffic'
          destinations: ['Internet']
          nextHop: routingIntentNextHop
        }
      ] : (privateTrafficRoutingPolicy && !internetTrafficRoutingPolicy) ? [
        {
          name: 'PrivateTraffic'
          destinations: ['PrivateTraffic']
          nextHop: routingIntentNextHop
        }
      ] : []
  }
}
