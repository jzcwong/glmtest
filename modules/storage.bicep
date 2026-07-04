// Storage account module — resourceGroup scope.
// Called by main.bicep after the resource group has been created.
// NOTE: Anonymous public access is intentionally enabled per requirements.

@description('Name of the storage account. Must be globally unique, lowercase, 3-24 chars, alphanumeric only.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Azure region for the storage account. Singapore = southeastasia.')
param location string = 'southeastasia'

@description('SKU / redundancy tier for the storage account.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param skuName string = 'Standard_LRS'

@description('Kind of storage account to create.')
@allowed([
  'StorageV2'
  'Storage'
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
])
param kind string = 'StorageV2'

@description('Access tier for BlobStorage / StorageV2 accounts.')
@allowed([
  'Hot'
  'Cool'
])
param accessTier string = 'Hot'

@description('Optional container configured for anonymous public read access.')
param createPublicContainer bool = true
@description('Name of the public container (only created if createPublicContainer is true).')
param publicContainerName string = 'public'

// --- Storage account ---
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: kind
  properties: {
    accessTier: accessTier
    // Intentionally allow anonymous public access at the account level.
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      // Open: allow traffic from all networks. Public access relies on this.
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Example publicly-readable container. Container-level publicAccess = 'Container'
// means anonymous clients can list and read blobs in this container.
// Set to 'Blob' to allow anonymous reads of individual blobs but not listing.
resource publicContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = if (createPublicContainer) {
  name: '${storageAccount.name}/default/${publicContainerName}'
  properties: {
    publicAccess: 'Container'
  }
}

@description('Provisioning state and endpoint details for the created storage account.')
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output publicContainerName string = createPublicContainer ? publicContainerName : ''
