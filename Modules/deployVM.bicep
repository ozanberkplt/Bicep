// Required parameters
import { regionType } from '.shared/commonTypes.bicep'
param regionAbbreviation regionType
param VMName string
param subnetName string

// Importing OS type
import {OSType} from '.shared/commonTypes.bicep'
param TypeofOS OSType

// Importing VM size type
import {vmSizeType} from '.shared/commonTypes.bicep'
param SizeOfVM vmSizeType

// Locations Module
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

// VM Size and OS Mapping
var vmSize = loadJsonContent('.shared/vmSizes.json')
var vmSizeValue = vmSize[SizeOfVM]
var OSMapping = loadJsonContent('.shared/VM_OS.json')
var OS = OSMapping[TypeofOS]

// Windows or Linux check
var isWindows = contains(toLower(TypeofOS), 'windows')

var imageReference = isWindows
  ? {
      id: OS.Windows.resourceId
    }
  : {
      publisher: OS.Linux.publisher
      offer: OS.Linux.offer
      sku: OS.Linux.sku
      version: OS.Linux.version
    }



resource Existing_Subnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  name: subnetName
}

module VM 'br/public:avm/res/compute/virtual-machine:0.17.0' = {
  params: {
    name: VMName
    location: location
    adminUsername: 'gunvoradmin'
    availabilityZone: -1
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            subnetResourceId: Existing_Subnet.id
            privateIPAllocationMethod: 'Dynamic'
            privateIPAddressVersion: 'IPv4'            
          }
        ]
      }
    ]
    adminPassword: 'P@ssw0rd1234!'
    osDisk:{
      managedDisk: {}
    }
    managedIdentities:{
      systemAssigned: true
    }
    osType: OS.type
    vmSize: vmSizeValue
    secureBootEnabled: true
    computerName: VMName
    imageReference: imageReference
    publicNetworkAccess: 'Disabled'
    licenseType: isWindows ? 'Windows_Server' : ''
    
  }
}
