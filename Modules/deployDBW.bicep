targetScope = 'subscription'
param regionAbbreviation string
param PrivateSubnetName string 
param PublicSubnetName string 
param PrivateSubnetAddressSpace string
param PublicSubnetAddressSpace string 
param subscriptionId string 
param projectName string
param VNETRG string
param Owner string
param CostCenter string
param dataResourceGroup string

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
  scope: resourceGroup(VNETRG)
}

resource Existing_routeTable 'Microsoft.Network/routeTables@2024-07-01' existing = {
  name: 'rt-vnet-${projectName}-swn'
  scope: resourceGroup(VNETRG)
}

resource Existing_PESubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: Existing_VNET
  name: 'sn-${projectName}-pe-swn'
}

module Create_DataRG 'br/public:avm/res/resources/resource-group:0.4.1' = {
  scope: subscription(subscriptionId)
  name: dataResourceGroup
  params: {
    name: dataResourceGroup
    tags: {
      Owner: Owner
      CostCenter: CostCenter
    }
    location: location
  }  
}

module Create_NSG 'br/public:avm/res/network/network-security-group:0.5.1' = {
  name: 'NSG'
  scope: resourceGroup(dataResourceGroup)
  params: {
    name: 'nsg-${projectName}-swn'
    location: location
  }
  dependsOn: [
    Create_DataRG
  ]
}

module Create_DWHPrivateSubnet 'br/public:avm/res/network/virtual-network/subnet:0.1.2' = {
  scope: resourceGroup(VNETRG)
  name: 'DWHPrivateSubnet'
  params: {
    name: PrivateSubnetName
    virtualNetworkName: Existing_VNET.name
    addressPrefix: PrivateSubnetAddressSpace
    routeTableResourceId: Existing_routeTable.id
    delegation: 'Microsoft.Databricks/workspaces'
    networkSecurityGroupResourceId: Create_NSG.outputs.resourceId
  }
}

module Create_DWHPublicSubnet 'br/public:avm/res/network/virtual-network/subnet:0.1.2' = {
  scope: resourceGroup(VNETRG)
  name: 'DWHPublicSubnet'
  params: {
    name: PublicSubnetName
    virtualNetworkName: Existing_VNET.name
    addressPrefix: PublicSubnetAddressSpace
    routeTableResourceId: Existing_routeTable.id
    delegation: 'Microsoft.Databricks/workspaces'
    networkSecurityGroupResourceId: Create_NSG.outputs.resourceId
  }
  dependsOn: [
    Create_DWHPrivateSubnet
  ]
}

module Create_DBW 'br/public:avm/res/databricks/workspace:0.11.2' = {
  scope: resourceGroup(dataResourceGroup)
  name: 'DBW_Prod'
  params: {
    name: naming.outputs.databricksWorkspaceName
    location: location
    customPrivateSubnetName: PrivateSubnetName
    customPublicSubnetName: PublicSubnetName
    publicNetworkAccess: 'Disabled'
    skuName: 'premium'
    customVirtualNetworkResourceId: Existing_VNET.id
    disablePublicIp: true
    requiredNsgRules: 'NoAzureDatabricksRules'
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: PrivateDNSZones.databricks.dnsZone
            }
          ]
        }
        service: PEServices.databricks_ui_api.service
        subnetResourceId: Existing_PESubnet.id
        name: naming.outputs.pe_dbw_api
      }
      {
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: PrivateDNSZones.databricks.dnsZone
            }
          ]
        }
        service: PEServices.databricks_browser_authentication.service
        subnetResourceId: Existing_PESubnet.id
        name: naming.outputs.pe_dbw_auth
      }
    ]
  }
  dependsOn: [
    Create_DataRG
    Create_DWHPrivateSubnet
    Create_DWHPublicSubnet
  ]
}
