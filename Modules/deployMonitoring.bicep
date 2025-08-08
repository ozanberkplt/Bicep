@allowed([
  'swn'
  'usc'
])
param projectName string

// Variables to hold the name of the Log Analytics workspace and Application Insights resource
var LogName = 'log-${projectName}-${regionAbbreviation}'
var AppInsightsName = 'appi-${projectName}-${regionAbbreviation}'
import { regionType } from '.shared/commonTypes.bicep'
param regionAbbreviation regionType
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

resource Log 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: LogName
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      legacy: 0
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource AppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: AppInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: Log.id
  }
}
output logAnalyticsWorkspaceId string = Log.id
output appInsightsId string = AppInsights.id
