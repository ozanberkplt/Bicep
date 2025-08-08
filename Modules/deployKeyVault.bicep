@allowed([
  'swn'
  'usc'
  ''
])

import { regionType } from '.shared/commonTypes.bicep'
param regionAbbreviation regionType
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

param projectName string
param vNetName string
param vNetRG string
param peSubnetName string

// Variables
var kvName = 'kv-${projectName}-${regionAbbreviation}'
var peName = 'pe-kv-${projectName}-${regionAbbreviation}'
var kvID = resourceId('Microsoft.KeyVault/vaults', kvName)
var subnetId = 'subscriptions/${subscription().subscriptionId}/resourceGroups/${vNetRG}/providers/Microsoft.Network/virtualNetworks/${vNetName}/subnets/${peSubnetName}'
var PrivateDNSZones = json(loadTextContent('.shared/privateDnsZones.json'))

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: kvName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    enabledForDeployment: false
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
  }
}

// Private Endpoint for Key Vault
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: peName
  location: location
  dependsOn: [
    keyVault
  ]
  properties: {
    privateLinkServiceConnections: [
      {
        name: peName
        id: '${resourceId('Microsoft.Network/privateEndpoints', peName)}/privateLinkServiceConnections/${peName}'
        properties: {
          privateLinkServiceId: kvID
          groupIds: [
            'vault'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${peName}-nic'
    subnet: {
      id: subnetId
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

// Private DNS Zone Group
resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: PrivateDNSZones.keyvault.configName
        properties: {
          privateDnsZoneId: PrivateDNSZones.keyvault.dnsZone
        }
      }
    ]
  }
}
