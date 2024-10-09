// URL to Azure Kubernetes Service Bicep template
// https://learn.microsoft.com/en-us/azure/templates/microsoft.containerservice/managedclusters?pivots=deployment-language-bicep

// target scope
targetScope = 'resourceGroup'

// Variables
param adminUsername string
param clusterName string
param nodeCount int
param nodeSize string
param keyData string
param logAnalyticsWorkspaceId string
param aksIdentityId string
param aksKubeletIdentityId string
param tags object = {}

// AKS Cluster
resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-03-02-preview' = {
  name: clusterName
  location: resourceGroup().location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksIdentityId}': {}
    }
  }

  properties: {
    dnsPrefix: clusterName
    agentPoolProfiles: [
      {
        name: 'system1'
        count: nodeCount
        vmSize: nodeSize
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: true
        minCount: 2
        maxCount: 5
      }
    ]
    linuxProfile: {
      adminUsername: adminUsername
      ssh: {
        publicKeys: [
          {
            keyData: keyData
          }
        ]
      }
    }
    azureMonitorProfile: {
      metrics: {
        enabled: false
      }
      containerInsights: {
        enabled: true
        disablePrometheusMetricsScraping: true
        logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceId
      }
    }
    identityProfile: {
      kubeletidentity: {
        resourceId: aksKubeletIdentityId
      }
    }
  }
}

resource aksDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${clusterName}-diagnostics'
  scope: aksCluster
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'kube-apiserver'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'kube-controller-manager'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'kube-scheduler'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'kube-audit'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'kube-audit-admin'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'guard'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

// Output
output aksName string = aksCluster.name
output aksResourceId string = aksCluster.id
