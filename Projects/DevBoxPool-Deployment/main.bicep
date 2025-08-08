import { regionType } from '../../modules/.shared/commonTypes.bicep'
param regionAbbreviation regionType
param projectName string
param DevCenterName string
param UserID string

module DeployResource 'deploy.bicep'  = {
  params: {
    regionAbbreviation: regionAbbreviation
    projectName: projectName
    DevCenterName: DevCenterName
  }
}

module DeployPermissions 'permissions.bicep' = {
  params: {
    projectName: projectName
    DevCenterName: DevCenterName
    UserID: UserID
  }
  dependsOn: [
    DeployResource
  ]
}
