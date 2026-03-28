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
# yaml-language-server: $schema=./.vscode/cross-tenant-access.schema.json
inbound:
  b2b_collaboration:
    access_type: "allowed"
  b2b_direct_connect:
    access_type: "blocked"
  trust:
    mfa_accepted: false
    compliant_device_accepted: false
    hybrid_azure_ad_joined_device_accepted: false

outbound:
  b2b_collaboration:
    access_type: "allowed"
  b2b_direct_connect:
    access_type: "blocked"

tenant_restrictions:
  access_type: "blocked"
```

### `peers.yaml`
List specific partner organizations with their overrides. Here is a full example for a partner with all supported features:
```yaml
- name: "Partner Org"
  tenant_id: "00000000-0000-0000-0000-000000000000"
  inbound:
    trust:
      mfa_accepted: true
      compliant_device_accepted: true
      hybrid_azure_ad_joined_device_accepted: true
    automatic_user_consent: true
    identity_sync:
      user: true
      group: true
    b2b_collaboration:
      access_type: "allowed"
  outbound:
    automatic_user_consent: true
    b2b_collaboration:
      access_type: "allowed"
  tenant_restrictions:
    access_type: "allowed"
```

## IDE Support (VS Code)

To get auto-completion, validation, and hover documentation in your YAML files:
1.  Install the [RedHat YAML extension](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) for VS Code.
2.  The project includes a JSON schema in `.vscode/cross-tenant-access.schema.json`.
3.  The schema is automatically mapped to `defaults.yaml` and `peers.yaml` via `.vscode/settings.json`.

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
terraform import 'microsoft365wp_cross_tenant_identity_sync_policy_partner.peers["<partner-tenant-id>"]' <partner-tenant-id>
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
