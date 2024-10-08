targetScope = 'resourceGroup'

param keyData string
param sshKeyName string
param tags object = {}

resource sshKey 'Microsoft.Compute/sshPublicKeys@2024-03-01' = {
  name: sshKeyName
  location: resourceGroup().location
  tags: tags
  properties: {
    publicKey: keyData
  }
}

output sshKey string = sshKey.properties.publicKey
