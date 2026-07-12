// Resource-group-scoped by design (targetScope defaults to 'resourceGroup') - the group itself is
// created once, manually, per AZURE_SETUP_TODO.md, so the GitHub Actions deploy identity's RBAC
// can stay scoped to just this one resource group rather than the whole subscription.
//
// Adapted from Microsoft's own Flex Consumption reference (needed for the .NET 10 runtime, which
// classic Linux Consumption doesn't support):
// https://github.com/Azure-Samples/azure-functions-flex-consumption-samples/blob/main/IaC/bicep/main.bicep
// Differences from that sample: resource-group scope instead of subscription scope (no
// environmentName/azd tags), the Azure Communication Services Email chain, CORS, and the
// contact-form-specific app settings.

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Short prefix used when naming resources in this resource group.')
param namePrefix string = 'matpadley-contact'

@description('Origins allowed to call the contact form function (platform CORS + the Origin check in ContactFunction.cs).')
param allowedOrigins array = [
  'https://matpadley.github.io'
]

@description('Azure Communication Services data residency. See az communication email create --data-location for accepted values (e.g. "UK", "United States", "Europe").')
param dataLocation string = 'UK'

@description('.NET version for the isolated-worker Function App runtime on Flex Consumption.')
param functionAppRuntimeVersion string = '10.0'

@minValue(40)
@maxValue(1000)
param maximumInstanceCount int = 40

@allowed([512, 2048, 4096])
param instanceMemoryMB int = 2048

@description('Real inbox the contact form delivers to. Passed in at deploy time (GitHub secret -> secure param) - never written to a file in this repo.')
@secure()
param contactRecipientEmail string

var resourceToken = toLower(uniqueString(resourceGroup().id))
var functionAppName = '${namePrefix}-func-${resourceToken}'
var storageAccountName = 'st${resourceToken}'
var deploymentStorageContainerName = 'app-package-${take(functionAppName, 32)}-${take(resourceToken, 7)}'

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.11.1' = {
  name: 'logAnalytics'
  params: {
    name: '${namePrefix}-logs-${resourceToken}'
    location: location
    dataRetention: 30
  }
}

module applicationInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: 'applicationInsights'
  params: {
    name: '${namePrefix}-appi-${resourceToken}'
    location: location
    workspaceResourceId: logAnalytics.outputs.resourceId
    disableLocalAuth: true
  }
}

module storage 'br/public:avm/res/storage/storage-account:0.25.0' = {
  name: 'storage'
  params: {
    name: storageAccountName
    location: location
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    dnsEndpointType: 'Standard'
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    blobServices: {
      containers: [
        { name: deploymentStorageContainerName }
      ]
    }
    tableServices: {}
    queueServices: {}
    minimumTlsVersion: 'TLS1_2'
  }
}

module appServicePlan 'br/public:avm/res/web/serverfarm:0.1.1' = {
  name: 'appServicePlan'
  params: {
    name: '${namePrefix}-plan-${resourceToken}'
    location: location
    sku: {
      name: 'FC1'
      tier: 'FlexConsumption'
    }
    reserved: true
  }
}

module functionApp 'br/public:avm/res/web/site:0.16.0' = {
  name: 'functionApp'
  params: {
    kind: 'functionapp,linux'
    name: functionAppName
    location: location
    serverFarmResourceId: appServicePlan.outputs.resourceId
    managedIdentities: {
      systemAssigned: true
    }
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storage.outputs.primaryBlobEndpoint}${deploymentStorageContainerName}'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: maximumInstanceCount
        instanceMemoryMB: instanceMemoryMB
      }
      runtime: {
        name: 'dotnet-isolated'
        version: functionAppRuntimeVersion
      }
    }
    siteConfig: {
      alwaysOn: false
      cors: {
        allowedOrigins: allowedOrigins
      }
    }
    configs: [
      {
        name: 'appsettings'
        properties: {
          // Identity-based storage access (Flex Consumption default) - no connection string.
          AzureWebJobsStorage__credential: 'managedidentity'
          AzureWebJobsStorage__blobServiceUri: 'https://${storage.outputs.name}.blob.${environment().suffixes.storage}'
          AzureWebJobsStorage__queueServiceUri: 'https://${storage.outputs.name}.queue.${environment().suffixes.storage}'
          AzureWebJobsStorage__tableServiceUri: 'https://${storage.outputs.name}.table.${environment().suffixes.storage}'

          // Identity-based App Insights ingestion - no connection string secret either.
          APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.outputs.connectionString
          APPLICATIONINSIGHTS_AUTHENTICATION_STRING: 'Authorization=AAD'

          // Email: connection string is pulled from the ACS resource this same template just
          // created via listKeys() - it never leaves Azure. Sender address is derived from the
          // Azure-managed domain's auto-generated MailFrom subdomain.
          AcsConnectionString: communicationService.listKeys().primaryConnectionString
          EmailSender: 'DoNotReply@${emailDomain.properties.mailFromSenderDomain}'
          ContactRecipientEmail: contactRecipientEmail
          AllowedOrigins: join(allowedOrigins, ',')
        }
      }
    ]
  }
}

// Azure Communication Services Email, Azure-managed domain: no external email provider account
// and no DNS records to configure - Azure owns and auto-verifies the sending subdomain.
resource emailService 'Microsoft.Communication/emailServices@2023-04-01' = {
  name: '${namePrefix}-email-${resourceToken}'
  location: 'global'
  properties: {
    dataLocation: dataLocation
  }
}

resource emailDomain 'Microsoft.Communication/emailServices/domains@2023-04-01' = {
  parent: emailService
  name: 'AzureManagedDomain'
  location: 'global'
  properties: {
    domainManagement: 'AzureManaged'
    userEngagementTracking: 'Disabled'
  }
}

resource communicationService 'Microsoft.Communication/communicationServices@2023-04-01' = {
  name: '${namePrefix}-acs-${resourceToken}'
  location: 'global'
  properties: {
    dataLocation: dataLocation
    linkedDomains: [
      emailDomain.id
    ]
  }
}

// RBAC for the Function App's system-assigned identity: Flex Consumption needs these to reach
// its own storage account and to publish telemetry to its own Application Insights instance,
// since neither is wired up via a connection-string secret here. Split into its own module -
// see infra/rbac.bicep for why.
module rbac 'rbac.bicep' = {
  name: 'rbac'
  params: {
    storageAccountName: storage.outputs.name
    appInsightsName: applicationInsights.outputs.name
    managedIdentityPrincipalId: functionApp.outputs.?systemAssignedMIPrincipalId ?? ''
  }
}

output functionAppName string = functionApp.outputs.name
output functionAppUrl string = 'https://${functionApp.outputs.defaultHostname}/api/contact'
