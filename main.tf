resource "microsoft365wp_cross_tenant_access_policy_configuration_default" "this" {
  # Inbound Trust
  inbound_trust = {
    is_mfa_accepted                          = local.defaults_config.inbound_trust.is_mfa_accepted
    is_compliant_device_accepted             = local.defaults_config.inbound_trust.is_compliant_device_accepted
    is_hybrid_azure_ad_joined_device_accepted = local.defaults_config.inbound_trust.is_hybrid_azure_ad_joined_device_accepted
  }

  # B2B Collaboration Inbound
  b2b_collaboration_inbound = {
    users_and_groups = {
      access_type = local.defaults_config.b2b_collaboration_inbound.users_and_groups.access_type
      targets     = local.defaults_config.b2b_collaboration_inbound.users_and_groups.targets
    }
    applications = {
      access_type = local.defaults_config.b2b_collaboration_inbound.applications.access_type
      targets     = local.defaults_config.b2b_collaboration_inbound.applications.targets
    }
  }

  # B2B Collaboration Outbound
  b2b_collaboration_outbound = {
    users_and_groups = {
      access_type = local.defaults_config.b2b_collaboration_outbound.users_and_groups.access_type
      targets     = local.defaults_config.b2b_collaboration_outbound.users_and_groups.targets
    }
    applications = {
      access_type = local.defaults_config.b2b_collaboration_outbound.applications.access_type
      targets     = local.defaults_config.b2b_collaboration_outbound.applications.targets
    }
  }

  # B2B Direct Connect Inbound
  b2b_direct_connect_inbound = {
    users_and_groups = {
      access_type = local.defaults_config.b2b_direct_connect_inbound.users_and_groups.access_type
      targets     = local.defaults_config.b2b_direct_connect_inbound.users_and_groups.targets
    }
    applications = {
      access_type = local.defaults_config.b2b_direct_connect_inbound.applications.access_type
      targets     = local.defaults_config.b2b_direct_connect_inbound.applications.targets
    }
  }

  # B2B Direct Connect Outbound
  b2b_direct_connect_outbound = {
    users_and_groups = {
      access_type = local.defaults_config.b2b_direct_connect_outbound.users_and_groups.access_type
      targets     = local.defaults_config.b2b_direct_connect_outbound.users_and_groups.targets
    }
    applications = {
      access_type = local.defaults_config.b2b_direct_connect_outbound.applications.access_type
      targets     = local.defaults_config.b2b_direct_connect_outbound.applications.targets
    }
  }

  # Tenant Restrictions
  tenant_restrictions = {
    users_and_groups = {
      access_type = local.defaults_config.tenant_restrictions.users_and_groups.access_type
      targets     = local.defaults_config.tenant_restrictions.users_and_groups.targets
    }
    applications = {
      access_type = local.defaults_config.tenant_restrictions.applications.access_type
      targets     = local.defaults_config.tenant_restrictions.applications.targets
    }
  }

  # Note: automatic_user_consent_settings are read-only for the default configuration
}

resource "microsoft365wp_cross_tenant_access_policy_configuration_partner" "peers" {
  for_each = local.peers

  tenant_id = each.value.tenant_id

  # Inbound Trust
  inbound_trust = try(each.value.inbound.trust, null) != null ? {
    is_mfa_accepted                          = try(each.value.inbound.trust.mfa_accepted, null)
    is_compliant_device_accepted             = try(each.value.inbound.trust.compliant_device_accepted, null)
    is_hybrid_azure_ad_joined_device_accepted = try(each.value.inbound.trust.hybrid_azure_ad_joined_device_accepted, null)
  } : null

  # B2B Collaboration Inbound
  b2b_collaboration_inbound = try(each.value.inbound.b2b_collaboration, null) != null ? {
    users_and_groups = {
      access_type = each.value.inbound.b2b_collaboration.access_type
      targets     = [{ target = "AllUsers", target_type = "user" }]
    }
    applications = {
      access_type = each.value.inbound.b2b_collaboration.access_type
      targets     = [{ target = "AllApplications", target_type = "application" }]
    }
  } : null

  # B2B Collaboration Outbound
  b2b_collaboration_outbound = try(each.value.outbound.b2b_collaboration, null) != null ? {
    users_and_groups = {
      access_type = each.value.outbound.b2b_collaboration.access_type
      targets     = [{ target = "AllUsers", target_type = "user" }]
    }
    applications = {
      access_type = each.value.outbound.b2b_collaboration.access_type
      targets     = [{ target = "AllApplications", target_type = "application" }]
    }
  } : null

  # Tenant Restrictions
  tenant_restrictions = try(each.value.tenant_restrictions, null) != null ? {
    users_and_groups = {
      access_type = each.value.tenant_restrictions.access_type
      targets     = [{ target = "AllUsers", target_type = "user" }]
    }
    applications = {
      access_type = each.value.tenant_restrictions.access_type
      targets     = [{ target = "AllApplications", target_type = "application" }]
    }
  } : null

  # Automatic User Consent Settings
  automatic_user_consent_settings = {
    inbound_allowed  = try(each.value.inbound.automatic_user_consent, false)
    outbound_allowed = try(each.value.outbound.automatic_user_consent, false)
  }
}

resource "microsoft365wp_cross_tenant_identity_sync_policy_partner" "peers" {
  for_each = local.peers

  tenant_id    = each.value.tenant_id
  display_name = each.value.name

  user_sync_inbound = {
    is_sync_allowed = try(each.value.inbound.identity_sync.user, false)
  }

  group_sync_inbound = {
    is_sync_allowed = try(each.value.inbound.identity_sync.group, false)
  }
}
