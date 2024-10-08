targetScope = 'resourceGroup'

param lawname string
param tags object = {
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: lawname
  location: resourceGroup().location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
