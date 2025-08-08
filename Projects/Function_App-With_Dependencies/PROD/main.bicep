// This file is used to deploy a Function App with the specified parameters and all of it's dependencies.
targetScope = 'subscription'

param projectName string
param AppResourceGroup string
param DataResourceGroup string 
param MonitoringResourceGroup string
param regionAbbreviation string 
param sku string 
param osType string
param RuntimeStack string
param RuntimeVersion string
param vNetName string 
param vNetRG string 
param peSubnetName string 
param vNetAddressSpace string 
param subnetAddressSpace string
param subnetDescription string
param Owner string
param CostCenter string
param subscriptionId string = subscription().subscriptionId


module ResourceGroups '../../../modules/deployRGs.bicep' = {
  name: 'deployResourceGroups'
  scope: subscription(subscriptionId)
  params: {
    AppResourceGroup: AppResourceGroup
    DataResourceGroup: DataResourceGroup
    MonitoringResourceGroup: MonitoringResourceGroup
    regionAbbreviation: regionAbbreviation
    Owner: Owner
    CostCenter: CostCenter
    subscriptionId: subscriptionId
  }
}

module StorageAccount '../../../modules/deployStorageAccount.bicep' = {
  name: 'deployStorageAccount'
  scope: resourceGroup(subscriptionId, DataResourceGroup)
  params:{
    peSubnetName: peSubnetName
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    vNetName: vNetName
    vNetRG: vNetRG
  }
  dependsOn: [
    ResourceGroups
  ]
}


module AppServicePlan '../../../modules/deployASP.bicep' = {
  name: 'deployASP'
  scope: resourceGroup(subscriptionId, AppResourceGroup)
  params:{
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    sku: sku
    osType: osType
  }
  dependsOn: [
    ResourceGroups
  ]
}

module Monitoring '../../../modules/deployMonitoring.bicep' = {
  name: 'deployMonitoring'
  scope: resourceGroup(subscriptionId, MonitoringResourceGroup)
  params:{
    projectName: projectName
    regionAbbreviation: regionAbbreviation
  }
  dependsOn: [
    ResourceGroups
  ]
}

module KeyVault '../../../modules/deployKeyVault.bicep' = {
  name: 'deployKeyVault'
  scope: resourceGroup(subscriptionId, DataResourceGroup)
  params:{
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    peSubnetName: peSubnetName
    vNetName: vNetName
    vNetRG: vNetRG
  }
  dependsOn: [
    ResourceGroups
  ]
}

module OutgoingSubnet '../../../modules/deploySubnet.bicep' = {
  name: 'deployOutgoingSubnet'
  scope: resourceGroup(subscriptionId, vNetRG)
  params:{
    regionAbbreviation: regionAbbreviation
    vNetName: vNetName
    subnetDescription: subnetDescription
    subnetAddressSpace: subnetAddressSpace
    vNetAddressSpace: vNetAddressSpace
  }
  
}

module FunctionApp '../../../modules/deployFunc.bicep' = {
  name: 'deployFunctionApp'
  scope: resourceGroup(subscriptionId, AppResourceGroup)
  params:{
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    osType: osType
    appServicePlanId: AppServicePlan.outputs.appServicePlanId
    RuntimeStack: RuntimeStack
    RuntimeVersion: RuntimeVersion
    vNetName: vNetName
    vNetRG: vNetRG
    peSubnetName: peSubnetName
    storageAccountName: StorageAccount.outputs.SAName
    outboundSubnetID: OutgoingSubnet.outputs.subnetId
    storageAccountId: StorageAccount.outputs.SAID
  }
  dependsOn: [
    ResourceGroups
  ]
}
