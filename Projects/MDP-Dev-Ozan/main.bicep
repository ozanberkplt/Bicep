param projectName string
param regionAbbreviation string
param Project_ResourceGroup string
param NumberOfAgents int
param OrganizationName string
param AZDO_ProjectName string
param MDP_SubnetName string
param MDP_Subnet_AddressPrefix string
param vNet_Name string
param VMSize string
param OS string

var subscriptionId = subscription().id
var locations = loadJsonContent('../../modules/.shared/locations.json')
var location = locations[regionAbbreviation].region

var skuMap = loadJsonContent('../../modules/.shared/MDP_vmSKU.json')
var selectedSku = skuMap[VMSize]

var osMAP = loadJsonContent('../../modules/.shared/MDP_OS.json')
var selectedOS = osMAP[OS]

module naming '../../modules/.shared/naming_conventions.bicep' = {
  name: 'naming'
  scope: subscription(subscriptionId)
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}
resource Existing_Project 'Microsoft.DevCenter/projects@2025-07-01-preview' existing = {
  name: projectName
  scope: resourceGroup(Project_ResourceGroup)
}

module Create_MDP_Subnet 'br/public:avm/res/network/virtual-network/subnet:0.1.2' = {
  name: MDP_SubnetName
  scope: resourceGroup(Project_ResourceGroup)
  params: {
    name: MDP_SubnetName
    virtualNetworkName: vNet_Name
    addressPrefix: MDP_Subnet_AddressPrefix
    routeTableResourceId: 'rt-vnet-${projectName}-swn'
    delegation: 'Microsoft.DevCenter/pools'
    networkSecurityGroupResourceId: 'nsg-${projectName}-swn'
  }
}

module Create_MDP 'br/public:avm/res/dev-ops-infrastructure/pool:0.7.0' = {
  
  params: {
    name: naming.outputs.ManagedDevOpsPoolName
    agentProfile: {
      maxAgentLifetime: '7.00:00:00'
      gracePeriodTimeSpan: '7.00:00:00'
      kind: 'Stateful'
    }
    concurrency: NumberOfAgents
    location: location
    fabricProfileSkuName: selectedSku
    devCenterProjectResourceId: Existing_Project.id
    osProfile: {
      logonType: 'Service'
      secretsManagementSettings: {
        observedCertificates: []
        keyExportable: false
      }
    }
    images: [
        {
          aliases: [
            selectedOS.alias
          ]
          buffer: '*'
          wellKnownImageName: selectedOS.wellKnownImageName
        }
      ]
    storageProfile:{
      dataDisks:[
        {
          diskSizeGiB: 50
          storageAccountType:'Standard_LRS'
        }
      ]
    osDiskStorageAccountType:'Standard'
    }

    organizationProfile: {
      organizations: [
        {
          url: 'https://dev.azure.com/${OrganizationName}'
          projects: [
            AZDO_ProjectName
          ]
          parallelism: NumberOfAgents
          openAccess: false
        }
      ]
      permissionProfile: {
        kind: 'Inherit'
      }
      kind: 'AzureDevOps'
    }
  }

}
