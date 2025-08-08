@allowed([
  'swn'
  'usc'
])
param projectName string

@allowed([
  'P1V3'
])
param sku string

@allowed([
  'Windows'
  'Linux'
])
param osType string

var appServicePlanName = 'plan-${projectName}-${regionAbbreviation}'

import { regionType } from '.shared/commonTypes.bicep'
param regionAbbreviation regionType
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

var skuMap = {
  P1V3: {
    tier: 'PremiumV3'
    size: 'P1V3'
    family: 'PV3'
    kind: 'app'
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
  }
}

var skuConfig = skuMap[sku]

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuConfig.size
    tier: skuConfig.tier
    family: skuConfig.family
  }
  kind: skuConfig.kind
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: skuConfig.elasticScaleEnabled
    maximumElasticWorkerCount: skuConfig.maximumElasticWorkerCount
    isSpot: false
    reserved: osType == 'Linux'
    isXenon: false
    hyperV: false
    zoneRedundant: false
  }
}

output appServicePlanId string = appServicePlan.id
output appServicePlanName string = appServicePlan.name
