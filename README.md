# Azure Cross-Tenant Access Settings Management

Manage Microsoft Entra ID (Azure AD) cross-tenant access settings using Terraform, driven by YAML configuration.

## Project Overview

This project provides a declarative way to manage cross-tenant access settings (inbound, outbound, and tenant restrictions) using:
- **`defaults.yaml`**: Baseline settings for the entire tenant.
- **`peers.yaml`**: Specific overrides or configurations for partner organizations.
- **Terraform**: Uses the `terraprovider/microsoft365wp` provider to apply settings via the Microsoft Graph API.

## Configuration Files

### `defaults.yaml`
Define baseline settings for your tenant. For example:
```yaml
inbound:
  b2b_collaboration:
    access_type: "allowed"
  b2b_direct_connect:
    access_type: "blocked"
  trust:
    mfa_accepted: true
    compliant_device_accepted: true
    hybrid_azure_ad_joined_device_accepted: true

outbound:
  b2b_collaboration:
    access_type: "allowed"
  b2b_direct_connect:
    access_type: "blocked"

tenant_restrictions:
  access_type: "allowed"
```

### `peers.yaml`
List specific partner organizations with their overrides:
```yaml
- name: "Partner Org"
  tenant_id: "00000000-0000-0000-0000-000000000000"
  inbound:
    trust:
      mfa_accepted: true
  outbound:
    b2b_collaboration:
      access_type: "allowed"
```

## Setup with `direnv`

1. Copy the example `.envrc`:
   ```bash
   cp .envrc.example .envrc
   ```
2. Update `.envrc` with your Azure service principal credentials:
   - `ARM_TENANT_ID`
   - `ARM_CLIENT_ID`
   - `ARM_CLIENT_SECRET`
3. Allow `direnv`:
   ```bash
   direnv allow
   ```

## Terraform Usage

### Initialize
```bash
terraform init
```

### Import Existing State
Since these settings often already exist in Entra ID, you may need to import them into your Terraform state.

#### Import Defaults
```bash
terraform import microsoft365wp_cross_tenant_access_policy_configuration_default.this default
```

#### Import a Peer
```bash
# Replace <partner-tenant-id> with the actual Tenant ID
terraform import 'microsoft365wp_cross_tenant_access_policy_configuration_partner.peers["<partner-tenant-id>"]' <partner-tenant-id>
```

### Plan and Apply
```bash
terraform plan
terraform apply
```

## Prerequisites
- Terraform >= 1.0
- Microsoft Graph API permissions for the service principal:
  - `Policy.ReadWrite.CrossTenantAccess`
  - `Policy.Read.All`
