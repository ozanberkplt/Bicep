param regionAbbreviation string
param projectName string
param VNetName string
param vNetRG string
param peSubnetName string

module DeploySA '../../modules/deployStorageAccount.bicep' = {
  name: 'DeployStorageAccount'
  params: {
    projectName: projectName
    vNetName: VNetName
    vNetRG: vNetRG
    peSubnetName: peSubnetName
    regionAbbreviation: regionAbbreviation
  }
}
