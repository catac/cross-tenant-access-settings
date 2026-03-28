terraform {
  required_version = ">= 1.0"

  required_providers {
    microsoft365wp = {
      source  = "terraprovider/microsoft365wp"
      version = "~> 0.18.0" # Adjusting to a likely initial version, search didn't specify exact latest
    }
  }
}

provider "microsoft365wp" {
  # Configuration handled via environment variables:
  # ARM_TENANT_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET, etc.
}
