targetScope = 'resourceGroup'

param aksName string
param tags object = {
}

resource aksIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${aksName}-identity'
  location: resourceGroup().location
  tags: tags
}

output identityId string = aksIdentity.id
output principalId string = aksIdentity.properties.principalId
