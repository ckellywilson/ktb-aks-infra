targetScope = 'resourceGroup'

param aksClusterName string
param tags object = {
}

resource aksKubeletIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${aksClusterName}-kubelet-identity'
  location: resourceGroup().location
  tags: tags
}

output id string = aksKubeletIdentity.id
output principalId string = aksKubeletIdentity.properties.principalId
