targetScope = 'subscription'

param subscriptionId string
param AppResourceGroup string
param DataResourceGroup string
param MonitoringResourceGroup string
import { regionType } from '.shared/commonTypes.bicep'
param regionAbbreviation regionType
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region
param Owner string
param CostCenter string

module AppRG 'br/public:avm/res/resources/resource-group:0.4.1' = {
  scope: subscription(subscriptionId)
  name: AppResourceGroup
  params: {
    name: AppResourceGroup
    tags: {
      Owner: Owner
      CostCenter: CostCenter
    }
    location: location
  }  
}
output appresourcegroupName string = AppRG.name


module DataRG 'br/public:avm/res/resources/resource-group:0.4.1' = {
  scope: subscription(subscriptionId)
  name: DataResourceGroup
  params: {
    name: DataResourceGroup
    tags: {
      Owner: Owner
      CostCenter: CostCenter
    }
    location: location
  }  
}
output dataresourcegroupName string = DataRG.name

module MonitorRG 'br/public:avm/res/resources/resource-group:0.4.1' = {
  scope: subscription(subscriptionId)
  name: MonitoringResourceGroup
  params: {
    name: MonitoringResourceGroup
    tags: {
      Owner: Owner
      CostCenter: CostCenter
    }
    location: location
  }  
}
output monitoringresourcegroupName string = MonitorRG.name
