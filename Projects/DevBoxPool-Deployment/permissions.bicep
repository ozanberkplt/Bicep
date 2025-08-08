param projectName string
param DevCenterName string
param UserID string

resource DevCenter 'Microsoft.DevCenter/devcenters@2025-04-01-preview' existing = {
  name: DevCenterName
}
resource newproject 'Microsoft.DevCenter/projects@2025-04-01-preview' existing =  {
  name: projectName
}

resource DevBoxUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(DevCenter.id, UserID, 'DevBoxUserRole')
  scope: newproject
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/45d50f46-0b78-4001-a660-4198cbe8cd05' // Dev Box User
    principalType: 'User'
    principalId: UserID
  }
}
