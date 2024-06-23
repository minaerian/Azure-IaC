// Parameters
@description('Required. The name of the parent CDN profile. Required if the template is used in a standalone deployment.')
param profileName string

@description('Required. The name of the security policy.')
param name string

@description('Optional. Web Application Firewall associations for the security policy.')
param associations array = []

@description('Required. The ID of the Web Application Firewall policy.')
param wafPolicy string

// Resources
resource profile 'Microsoft.Cdn/profiles@2021-06-01' existing = {
  name: profileName
}

resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = {
  name: name
  parent: profile
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      associations: associations
      wafPolicy: {
        id: wafPolicy
      }
    }
  }
}

// Outputs
@description('The name of the security policy.')
output name string = securityPolicy.name

@description('The resource ID of the security policy.')
output resourceId string = securityPolicy.id


