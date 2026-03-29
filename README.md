# Azure Cross-Tenant Access Settings Management

Manage Microsoft Entra ID (Azure AD) cross-tenant access settings using Terraform, driven by YAML configuration.

## Project Overview

This project provides a declarative way to manage cross-tenant access settings (inbound, outbound, and tenant restrictions) using:
- **`config/defaults.yaml`**: Baseline settings for the entire tenant.
- **`config/peers.yaml`**: Specific overrides or configurations for partner organizations.
- **Terraform**: Uses the `terraprovider/microsoft365wp` provider to apply settings via the Microsoft Graph API.

## Configuration Files

### `config/defaults.yaml`
Define baseline settings for your tenant.
### `config/peers.yaml`
List specific partner organizations with their overrides. 

**Validation**: The project automatically ensures that a `tenant_id` is not defined multiple times in `peers.yaml`. If duplicates are found, `terraform plan` will fail with a clear error message.

## IDE Support (VS Code)

To get auto-completion, validation, and hover documentation in your YAML files:
1.  Install the [RedHat YAML extension](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) for VS Code.
2.  The project includes a JSON schema in `.vscode/cross-tenant-access.schema.json`.
3.  The schema is automatically mapped to YAML files via `.vscode/settings.json`.

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

## Export Existing Configuration

You can use the helper script to export your current Entra ID cross-tenant partners into `config/peers.yaml`. The script uses [uv](https://github.com/astral-sh/uv) for zero-setup execution:

1.  Run the export script (ensure your environment variables are set via `direnv`):
    ```bash
    uv run scripts/export_peers.py
    ```

## Terraform Usage

### Initialize
```bash
terraform init
```

### Import Existing State
If you have already configured settings in Entra ID, you can import them into your Terraform state.

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
- [uv](https://github.com/astral-sh/uv) (for running the export script)
- Microsoft Graph API permissions for the service principal:
  - `Policy.ReadWrite.CrossTenantAccess`
  - `Policy.Read.All`
