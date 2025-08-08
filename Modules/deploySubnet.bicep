param vNetName string
param subnetDescription string
param subnetAddressSpace string
param vNetAddressSpace string


import { regionType } from '.shared/commonTypes.bicep'
param regionAbbreviation regionType
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region


var vNetShortName = split(vNetName, '-')[1]
var SubNetFullName = 'sn-${vNetShortName}-${subnetDescription}-${regionAbbreviation}'
var routeTableName = 'rt-${vNetName}'
var nsgName = 'nsg-${SubNetFullName}'
var allOnPremCIDR = '10.0.0.0/8'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_All_InsideSubnet'
        properties: {
          priority: 4093
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: subnetAddressSpace
          destinationAddressPrefix: subnetAddressSpace
        }
      }
      {
        name: 'Deny_All_FromOtherSubnetsInVnet'
        properties: {
          priority: 4094
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: vNetAddressSpace
          destinationAddressPrefix: subnetAddressSpace
        }
      }
      {
        name: 'Allow_All_FromOnPremAndOtherVnets'
        properties: {
          priority: 4095
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: allOnPremCIDR
          destinationAddressPrefix: subnetAddressSpace
        }
      }
      {
        name: 'Deny_All_Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource routeTable 'Microsoft.Network/routeTables@2023-11-01' = {
  name: routeTableName
  location: location
  properties: {
    routes: [
      {
        name: 'Traffic_to_LB'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: locations[regionAbbreviation].nextHopIp
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: '${vNetName}/${SubNetFullName}'
  properties: {
    addressPrefix: subnetAddressSpace
    networkSecurityGroup: {
      id: nsg.id
    }
    routeTable: {
      id: routeTable.id
    }
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

output subnetId string = subnet.id
output nsgId string = nsg.id
output routeTableId string = routeTable.id
output outboundSubnetName string = SubNetFullName
