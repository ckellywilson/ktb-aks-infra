using './main.bicep'

param resourceGroupName = ''
param location = ''
param keyData = ''
param prefix = ''
param nodeSize = ''
param adminUserId = ''
param tags = {
  project: 'ktb-mod4'
}
