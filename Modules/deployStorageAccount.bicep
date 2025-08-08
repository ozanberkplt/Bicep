@maxLength(18)
param projectName string
param vNetName string
param vNetRG string
param peSubnetName string

import { regionType } from '.shared/commonTypes.bicep'
param regionAbbreviation regionType
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region


// Variables
var storageAccountName = 'gun${projectName}${regionAbbreviation}'
var BlobName = 'pe-${storageAccountName}-blob-${regionAbbreviation}'
var FileName = 'pe-${storageAccountName}-file-${regionAbbreviation}'
var TableName = 'pe-${storageAccountName}-table-${regionAbbreviation}'
var QueueName = 'pe-${storageAccountName}-queue-${regionAbbreviation}'
var subnetId = 'subscriptions/${subscription().subscriptionId}/resourceGroups/${vNetRG}/providers/Microsoft.Network/virtualNetworks/${vNetName}/subnets/${peSubnetName}'
var PrivateDNSZones = json(loadTextContent('.shared/privateDnsZones.json'))

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowedCopyScope: 'PrivateLink'
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    allowCrossTenantReplication: false
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}
var StorageAccountID string = storageAccount.id

resource storageAccountName_default 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource Microsoft_Storage_storageAccounts_fileServices_storageAccountName_default 'Microsoft.Storage/storageAccounts/fileServices@2023-04-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource Blob 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: BlobName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: BlobName
        properties: {
          privateLinkServiceId: StorageAccountID
          groupIds: [
            'blob'
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
    customNetworkInterfaceName: '${BlobName}-nic'
    subnet: {
      id: subnetId
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource BlobName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: Blob
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: PrivateDNSZones.blob.configName
        properties: {
          privateDnsZoneId: PrivateDNSZones.blob.dnsZone
        }
      }
    ]
  }
}

resource File 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: FileName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: FileName
        properties: {
          privateLinkServiceId: StorageAccountID
          groupIds: [
            'file'
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
    customNetworkInterfaceName: '${FileName}-nic'
    subnet: {
      id: subnetId
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource FileName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: File
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: PrivateDNSZones.file.configName
        properties: {
          privateDnsZoneId: PrivateDNSZones.file.dnsZone
        }
      }
    ]
  }
}

resource Table 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: TableName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: TableName
        properties: {
          privateLinkServiceId: StorageAccountID
          groupIds: [
            'table'
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
    customNetworkInterfaceName: '${TableName}-nic'
    subnet: {
      id: subnetId
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource TableName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: Table
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: PrivateDNSZones.table.configName
        properties: {
          privateDnsZoneId: PrivateDNSZones.table.dnsZone
        }
      }
    ]
  }
}

resource Queue 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: QueueName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: QueueName
        properties: {
          privateLinkServiceId: StorageAccountID
          groupIds: [
            'queue'
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
    customNetworkInterfaceName: '${QueueName}-nic'
    subnet: {
      id: subnetId
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource QueueName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: Queue
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: PrivateDNSZones.queue.configName
        properties: {
          privateDnsZoneId: PrivateDNSZones.queue.dnsZone
        }
      }
    ]
  }
}

output SAID string = storageAccount.id
output SAName string = storageAccount.name
output blobPrivateEndpointId string = Blob.id
output filePrivateEndpointId string = File.id
output tablePrivateEndpointId string = Table.id
output queuePrivateEndpointId string = Queue.id
