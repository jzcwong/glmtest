// Azure Bicep template — Resource group + Storage account in Singapore (Southeast Asia)
// Subscription-scoped so it can create the resource group itself, then deploys
// the storage account into that RG via a module.
// NOTE: Anonymous public access is intentionally enabled per requirements.

targetScope = 'subscription'

@description('Name of the resource group to create. 1-90 chars, alphanumerics/.-_() and not ending in a dot.')
@minLength(1)
@maxLength(90)
param resourceGroupName string

@description('Name of the storage account. Must be globally unique, lowercase, 3-24 chars, alphanumeric only.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Azure region for the resource group and storage account. Singapore = southeastasia.')
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

// --- Resource group (owned by this template) ---
resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: resourceGroupName
  location: location
}

// --- Storage account (deployed into the RG above via module) ---
module storage 'modules/storage.bicep' = {
  name: 'storageDeploy'
  scope: resourceGroup
  params: {
    storageAccountName: storageAccountName
    location: location
    skuName: skuName
    kind: kind
    accessTier: accessTier
    createPublicContainer: createPublicContainer
    publicContainerName: publicContainerName
  }
}

@description('Provisioning state and endpoint details for the created storage account.')
output resourceGroupName string = resourceGroup.name
output storageAccountId string = storage.outputs.storageAccountId
output storageAccountName string = storage.outputs.storageAccountName
output primaryBlobEndpoint string = storage.outputs.primaryBlobEndpoint
output publicContainerName string = storage.outputs.publicContainerName
