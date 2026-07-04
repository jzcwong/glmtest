# Azure Storage Stack (Bicep + GitHub Actions)

A small Azure infrastructure-as-code stack that provisions a **resource group** and a **publicly-readable storage account** in the Singapore (`southeastasia`) region, plus a GitHub Actions workflow to deploy or destroy it on demand.

> ⚠️ **Intentionally public.** The storage account is configured with `allowBlobPublicAccess: true` and an open network ACL, and ships with a `public` container that allows anonymous list + read. Anything placed in that container is readable by anyone who has the URL. Only use this for genuinely public data.

## Files

| Path | Purpose |
|------|---------|
| `main.bicep` | Subscription-scoped template. Creates the resource group and calls the storage module. |
| `modules/storage.bicep` | Resource-group-scoped module. Creates the storage account (public access enabled) and the `public` container. |
| `.github/workflows/deploy-storage.yml` | Manual GitHub Actions workflow — deploy or destroy the stack via a dropdown. |
| `.gitignore` | Excludes `.claude/` from version control. |

## What the stack creates

- **Resource group** — named by you, in `southeastasia`.
- **Storage account** — `StorageV2`, `Standard_LRS`, Hot tier, TLS 1.2, HTTPS-only, with anonymous blob public access enabled and network ACLs set to `Allow`.
- **`public` container** — `publicAccess: 'Container'`, so anonymous clients can list and read blobs.

All parameters have defaults except `storageAccountName` and `resourceGroupName`.

## The workflow

`.github/workflows/deploy-storage.yml` is triggered manually (`workflow_dispatch`). It presents:

- **mode** — `deploy` (default) or `destroy`
- **storageAccountName** — required, 3–24 chars lowercase alphanumeric
- **resourceGroupName** — required, created on deploy / deleted on destroy
- **location** — optional, defaults to `southeastasia`

**Deploy** lints the Bicep, validates against Azure (what-if), then runs a subscription-scope `az deployment sub create`.

**Destroy** deletes the named resource group (which removes the storage account and its child container) and polls until deletion is confirmed.

Auth uses Azure OIDC federated identity — no stored secrets. Required GitHub variables: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.

## Local deploy (alternative)

```bash
az deployment sub create \
  --location southeastasia \
  --template-file main.bicep \
  --parameters resourceGroupName=<rg-name> \
               storageAccountName=<globally-unique-name> \
               location=southeastasia
```
