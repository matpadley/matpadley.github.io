// Split out from main.bicep because Microsoft.Authorization/roleAssignments' name/scope must be
// computable "at the start of deployment" - a storage account looked up via `existing` by a name
// that's itself a module output (storage.outputs.name) doesn't qualify inline in the same file
// (Bicep error BCP120). As a nested module, storageAccountName/appInsightsName arrive as already
// resolved plain strings, which does qualify. Matches the structure of the reference sample this
// infra is adapted from (see main.bicep header comment).

param storageAccountName string
param appInsightsName string
param managedIdentityPrincipalId string

// Storage Blob Data Owner / Storage Queue Data Contributor / Storage Table Data Contributor /
// Monitoring Metrics Publisher - Azure built-in role definition IDs.
var storageBlobDataOwnerRoleId = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
var storageQueueDataContributorRoleId = '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
var storageTableDataContributorRoleId = '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
var monitoringMetricsPublisherRoleId = '3913510d-42f4-4e42-8a64-420c390055eb'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource storageBlobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentityPrincipalId, storageBlobDataOwnerRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataOwnerRoleId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource storageQueueRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentityPrincipalId, storageQueueDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageQueueDataContributorRoleId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource storageTableRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentityPrincipalId, storageTableDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageTableDataContributorRoleId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource appInsightsRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(applicationInsights.id, managedIdentityPrincipalId, monitoringMetricsPublisherRoleId)
  scope: applicationInsights
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricsPublisherRoleId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}
