import { regionType } from '.shared/commonTypes.bicep'

@description('The Azure region where the resources will be deployed. This should match the region defined in the locations.json file.')
param regionAbbreviation regionType

@description('Tags to be applied to the resources, used for management and categorization.')
param tags object

@description('Description for the Azure Container Registry, used in naming conventions.')
param projectName string

@description('Name of the resource group where the virtual network is located.')
var vnetRGName = 'rg-vnet-${projectName}-${regionAbbreviation}'
@description('Name of the virtual network where the Azure Container Registry will be deployed.')
var vnetName = 'vnet-${projectName}-${regionAbbreviation}'
@description('Name of the subnet within the virtual network where the Azure Container Registry will be deployed.')
var subnetName = 'sn-${projectName}-pe-${regionAbbreviation}' 

var acrName = 'cr${projectName}${regionAbbreviation}'

var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region
var PrivateDNSZones = json(loadTextContent('.shared/privateDnsZones.json'))

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetRGName)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: subnetName
  parent: vnet
}

module registry 'br/public:avm/res/container-registry/registry:0.9.1' = {
  name: 'acrDeployment-${acrName}'
  params: {
    name: acrName
    acrAdminUserEnabled: false
    acrSku: 'Premium'
    azureADAuthenticationAsArmPolicyStatus: 'enabled'
    exportPolicyStatus: 'enabled'
    location: location
    publicNetworkAccess: 'Disabled'
    privateEndpoints: [
      {
        subnetResourceId: subnet.id
        name: 'pe-${acrName}-${regionAbbreviation}'
        customNetworkInterfaceName: 'pe-${acrName}-${regionAbbreviation}-nic'

        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: PrivateDNSZones.acr.dnsZone
            }
          ]
        }
      }
    ]
    quarantinePolicyStatus: 'disabled'
    softDeletePolicyStatus: 'disabled'
    softDeletePolicyDays: 7
    trustPolicyStatus: 'enabled'
    
    tags: tags
  }
}
