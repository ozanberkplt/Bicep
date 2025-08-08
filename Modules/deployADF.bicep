targetScope = 'subscription'
param regionAbbreviation string
param subscriptionId string 
param projectName string
param VNETRG string
param resourceGroup string

var PrivateDNSZones = json(loadTextContent('.shared/privatednszones.json'))
var PEServices = loadJsonContent('.shared/pe_services.json')
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

module naming '.shared/naming_conventions.bicep' = {
  name: 'naming'
  scope: subscription(subscriptionId)
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}

resource Existing_VNET 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: 'vnet-${projectName}-swn'
  scope: az.resourceGroup(VNETRG)
}

resource Existing_PESubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: Existing_VNET
  name: 'sn-${projectName}-pe-swn'
}

module Create_ADF 'br/public:avm/res/data-factory/factory:0.10.4' = {
  scope: az.resourceGroup(resourceGroup)
  name: 'ADF'
  params:{
    name: naming.outputs.dataFactoryName
    location: location
    publicNetworkAccess: 'Disabled'
    managedIdentities: {
      systemAssigned: true
    }
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: PrivateDNSZones.datafactory.dnsZone
            }
          ]
        }
        service: PEServices.datafactory_datafactory.service
        subnetResourceId: Existing_PESubnet.id
        name: naming.outputs.pe_adf_datafactory
      }
      {
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: PrivateDNSZones.datafactory.dnsZone
            }
          ]
        }
        service: PEServices.datafactory_portal.service
        subnetResourceId: Existing_PESubnet.id
        name: naming.outputs.pe_adf_portal
      }
    ]
  }
}
