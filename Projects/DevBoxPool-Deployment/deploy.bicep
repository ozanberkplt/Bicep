import { regionType } from '../../modules/.shared/commonTypes.bicep'
param regionAbbreviation regionType
param projectName string
param DevCenterName string
var DevBoxPoolName string = 'dbp-${projectName}-hybrid-${regionAbbreviation}'

var locations = loadJsonContent('../../modules/.shared/locations.json')
var location = locations[regionAbbreviation].region

resource DevCenter 'Microsoft.DevCenter/devcenters@2025-04-01-preview' existing = {
  name: DevCenterName
}

module DevBoxProjectAndPool 'br/public:avm/res/dev-center/project:0.1.0' = { 
params: {
  devCenterResourceId: DevCenter.id
  location: location
  name: projectName
  pools: [
    {
      name: DevBoxPoolName
      localAdministrator: 'Disabled'
      networkConnectionName: ''
      displayName: DevBoxPoolName
      devBoxDefinitionType: 'Reference'
      devBoxDefinitionName: ''
      virtualNetworkType: 'Unmanaged'
      stopOnDisconnect: {
        gracePeriodMinutes: 120
        status: 'Enabled'
      }
      stopOnNoConnect: {
        gracePeriodMinutes: 120
        status: 'Enabled'
      }
    }
  ]
}
}
