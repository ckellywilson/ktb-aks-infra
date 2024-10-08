// target scope
targetScope = 'subscription'

// parameters
param resourceGroupName string
param location string
param keyData string
param prefix string
param nodeSize string
param adminUserId string
param tags object

// variables
var aksName = '${prefix}-aks'
var adminUserName = 'ktbuser'
var acrName = '${prefix}acr${uniqueString(resourceGroupName)}'
var keyVaultName = '${prefix}kv${uniqueString(resourceGroupName)}'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module sshKey 'sshKey.bicep' = {
  scope: rg
  name: 'sshKey'
  params: {
    sshKeyName: '${prefix}-ssh-key'
    keyData: keyData
    tags: tags
  }
}

module kv 'kv.bicep' = {
  scope: rg
  name: 'keyVault'
  params: {
    keyVaultName: keyVaultName
    tags: tags
  }
  dependsOn: [
    aks
  ]
}

module acr 'acr.bicep' = {
  scope: rg
  name: 'acr'
  params: {
    acrName: acrName
    tags: tags
  }
}

module aks 'aks.bicep' = {
  scope: rg
  name: 'aks'
  params: {
    adminUsername: adminUserName
    clusterName: aksName
    nodeCount: 3
    nodeSize: nodeSize
    keyData: sshKey.outputs.sshKey
    logAnalyticsWorkspaceId: law.outputs.logAnalyticsWorkspaceId
    aksIdentityId: aksIdentity.outputs.identityId
    aksKubeletIdentityId: aksKubeletIdentity.outputs.id
    tags: tags
  }
  dependsOn: [
    sshKey
    law
    aksIdentity
    aksKubeletIdentity
    aksIdentityManagedIdentityOperatorRoleAssignment
  ]
}

module aksIdentity 'aksIdentity.bicep' = {
  scope: rg
  name: 'aksIdentity'
  params: {
    aksName: aksName
    tags: tags
  }
}

module aksKubeletIdentity 'aksKubeletIdentity.bicep' = {
  scope: rg
  name: 'aksKubeletIdentity'
  params: {
    aksClusterName: aksName
  }
}

module aksIdentityManagedIdentityOperatorRoleAssignment 'roleAssignment.bicep' = {
  scope: rg
  name: 'aksIdentityManagedIdentityOperatorRoleAssignment'
  params: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'f1a07417-d97a-45cb-824c-7a7467783830'
    ) // Managed Identity Operator
    principalId: aksIdentity.outputs.principalId
  }
  dependsOn: [
    aksIdentity
  ]
}

module aksIdentityKeyVaultSecretsUserRoleAssignment 'roleAssignment.bicep' = {
  scope: rg
  name: 'aksIdentityKeyVaultSecretsUserRoleAssignment'
  params: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
    ) // Key Vault Secrets User
    principalId: aksIdentity.outputs.principalId
  }
  dependsOn: [
    aksIdentity
    kv
  ]
}

module aksKubeletIdentityAcrPullRoleAssignment 'roleAssignment.bicep' = {
  scope: rg
  name: 'aksKubeletIdentityAcrPullRoleAssignment'
  params: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    ) // AcrPull
    principalId: aksKubeletIdentity.outputs.principalId
  }
  dependsOn: [
    acr
    aksKubeletIdentity
  ]
}

module law 'law.bicep' = {
  scope: rg
  name: 'law'
  params: {
    lawname: '${prefix}-law'
  }
}

module aks_monitor 'aks-monitor.bicep' = {
  scope: rg
  name: 'aks-monitor'
  params: {
    aksResourceId: aks.outputs.aksResourceId
    aksResourceLocation: location
    resourceTagValues: tags
    workspaceResourceId: law.outputs.logAnalyticsWorkspaceId
    dataCollectionInterval: '1m'
    enableContainerLogV2: true
    workspaceRegion: location
    namespaceFilteringModeForDataCollection: 'Include'
    namespacesForDataCollection: [
      'kube-system'
    ]
    streams: [
      'Microsoft-ContainerLog'
      'Microsoft-ContainerLogV2'
      'Microsoft-KubeEvents'
      'Microsoft-KubePodInventory'
      'Microsoft-KubeNodeInventory'
      'Microsoft-KubePVInventory'
      'Microsoft-KubeServices'
      'Microsoft-KubeMonAgentEvents'
      'Microsoft-InsightsMetrics'
      'Microsoft-ContainerInventory'
      'Microsoft-ContainerNodeInventory'
      'Microsoft-Perf'
    ]
  }
}

module workspace_based_app_insights 'workspace-based-app-insights.bicep' = {
  scope: rg
  name: 'workspaceBasedAppInsights'
  params: {
    appInsightsName: '${prefix}-ai'
    workspaceResourceId: law.outputs.logAnalyticsWorkspaceId
  }
}

output aksName string = aks.outputs.aksName
output resourceGroupName string = rg.name
