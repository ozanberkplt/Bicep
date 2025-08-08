targetScope = 'subscription'

param projectName string
param regionAbbreviation string
param subscriptionName string

// Normalize the subscription name for consistent naming -> This turns Gunvor-CloudOps-Test into cloudopstest
var normalizedSubscriptionName = toLower(replace(replace(subscriptionName, '-', ''), ' ', ''))

// Resource name variables
var storageAccountName = toLower('gun${projectName}${regionAbbreviation}')
var keyVaultName = 'kv-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var databricksWorkspaceName = 'dbw-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var dataFactoryName = 'adf-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var appServicePlanName = 'asp-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var webAppName = 'app-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var functionAppName = 'func-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var containerRegistryName = toLower('cr${projectName}${regionAbbreviation}')
var cosmosDbAccountName = '${projectName}${regionAbbreviation}cosmos'
var redisCacheName = 'redis-${projectName}-${regionAbbreviation}'
var resourceGroupName = 'rg-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var ManagedDevOpsPoolName = 'mdp-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'

// Private endpoint name variables
var pe_generic = 'pe-${projectName}-${regionAbbreviation}'
var pe_keyVault = 'pe-${keyVaultName}-${regionAbbreviation}'
var pe_blob = 'pe-${storageAccountName}-blob-${regionAbbreviation}'
var pe_file = 'pe-${storageAccountName}-file-${regionAbbreviation}'
var pe_queue = 'pe-${storageAccountName}-queue-${regionAbbreviation}'
var pe_table = 'pe-${storageAccountName}-table-${regionAbbreviation}'
var pe_cosmos = 'pe-${cosmosDbAccountName}-${regionAbbreviation}'
var pe_web = 'pe-${webAppName}-${regionAbbreviation}'
var pe_acr = 'pe-${containerRegistryName}-${regionAbbreviation}'
var pe_apim = 'pe-apim-${projectName}-${regionAbbreviation}' // assuming apimName not a separate var
var pe_adf_datafactory = 'pe-adf-${projectName}-datafactory-${regionAbbreviation}'
var pe_adf_portal = 'pe-adf-${projectName}-portal-${regionAbbreviation}'
var pe_dbw_auth = 'pe-dbw-${projectName}-auth-${regionAbbreviation}'
var pe_dbw_api = 'pe-dbw-${projectName}-api-${regionAbbreviation}'

// Resource Naming Outputs
output storageAccountName string = storageAccountName
output keyVaultName string = keyVaultName
output databricksWorkspaceName string = databricksWorkspaceName
output dataFactoryName string = dataFactoryName
output appServicePlanName string = appServicePlanName
output webAppName string = webAppName
output functionAppName string = functionAppName
output containerRegistryName string = containerRegistryName
output ManagedDevOpsPoolName string = ManagedDevOpsPoolName
output cosmosDbAccountName string = cosmosDbAccountName
output redisCacheName string = redisCacheName
output resourceGroupName string = resourceGroupName

// Private Endpoint Naming Outputs
output pe_generic string = pe_generic
output pe_keyVault string = pe_keyVault
output pe_blob string = pe_blob
output pe_file string = pe_file
output pe_queue string = pe_queue
output pe_table string = pe_table
output pe_cosmos string = pe_cosmos
output pe_web string = pe_web
output pe_acr string = pe_acr
output pe_apim string = pe_apim
output pe_adf_datafactory string = pe_adf_datafactory
output pe_adf_portal string = pe_adf_portal
output pe_dbw_auth string = pe_dbw_auth
output pe_dbw_api string = pe_dbw_api
