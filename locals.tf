locals {
  # Load and decode YAML files
  defaults_raw = yamldecode(file(var.defaults_file_path))
  peers_raw    = yamldecode(file(var.peers_file_path))

  # Prepare Defaults Configuration
  defaults_config = {
    # Inbound B2B Collaboration
    b2b_collaboration_inbound = {
      users_and_groups = {
        access_type = local.defaults_raw.inbound.b2b_collaboration.access_type
        targets = [
          { target = "AllUsers", target_type = "user" }
        ]
      }
      applications = {
        access_type = local.defaults_raw.inbound.b2b_collaboration.access_type
        targets = [
          { target = "AllApplications", target_type = "application" }
        ]
      }
    }

    # Inbound B2B Direct Connect
    b2b_direct_connect_inbound = {
      users_and_groups = {
        access_type = local.defaults_raw.inbound.b2b_direct_connect.access_type
        targets = [
          { target = "AllUsers", target_type = "user" }
        ]
      }
      applications = {
        access_type = local.defaults_raw.inbound.b2b_direct_connect.access_type
        targets = [
          { target = "AllApplications", target_type = "application" }
        ]
      }
    }

    # Outbound B2B Collaboration
    b2b_collaboration_outbound = {
      users_and_groups = {
        access_type = local.defaults_raw.outbound.b2b_collaboration.access_type
        targets = [
          { target = "AllUsers", target_type = "user" }
        ]
      }
      applications = {
        access_type = local.defaults_raw.outbound.b2b_collaboration.access_type
        targets = [
          { target = "AllApplications", target_type = "application" }
        ]
      }
    }

    # Outbound B2B Direct Connect
    b2b_direct_connect_outbound = {
      users_and_groups = {
        access_type = local.defaults_raw.outbound.b2b_direct_connect.access_type
        targets = [
          { target = "AllUsers", target_type = "user" }
        ]
      }
      applications = {
        access_type = local.defaults_raw.outbound.b2b_direct_connect.access_type
        targets = [
          { target = "AllApplications", target_type = "application" }
        ]
      }
    }

    # Inbound Trust
    inbound_trust = {
      is_mfa_accepted                          = lookup(local.defaults_raw.inbound.trust, "mfa_accepted", null)
      is_compliant_device_accepted             = lookup(local.defaults_raw.inbound.trust, "compliant_device_accepted", null)
      is_hybrid_azure_ad_joined_device_accepted = lookup(local.defaults_raw.inbound.trust, "hybrid_azure_ad_joined_device_accepted", null)
    }

    # Tenant Restrictions
    tenant_restrictions = {
      users_and_groups = {
        access_type = local.defaults_raw.tenant_restrictions.access_type
        targets = [
          { target = "AllUsers", target_type = "user" }
        ]
      }
      applications = {
        access_type = local.defaults_raw.tenant_restrictions.access_type
        targets = [
          { target = "AllApplications", target_type = "application" }
        ]
      }
    }
  }

  # Process peers - group by tenant_id to detect duplicates
  peers_grouped = { for peer in local.peers_raw : peer.tenant_id => peer... }

  # Find duplicate tenant IDs for error reporting
  duplicate_tenant_ids = [
    for tid, peer_list in local.peers_grouped : tid if length(peer_list) > 1
  ]

  # Final peers map (using the first entry for each tenant_id)
  peers = { for tid, peer_list in local.peers_grouped : tid => peer_list[0] }
}
