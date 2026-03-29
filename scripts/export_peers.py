# /// script
# dependencies = [
#   "requests",
#   "pyyaml",
# ]
# ///

import os
import sys
import json
import requests
import yaml

# Configuration
CONFIG_PATH = "config/peers.yaml"
SCHEMA_REF = "# yaml-language-server: $schema=../.vscode/cross-tenant-access.schema.json\n"

def get_token(client_id, client_secret, tenant_id):
    """Obtain OAuth2 token from Microsoft Entra ID (Azure AD)"""
    url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"
    data = {
        "client_id": client_id,
        "client_secret": client_secret,
        "scope": "https://graph.microsoft.com/.default",
        "grant_type": "client_credentials",
    }
    response = requests.post(url, data=data)
    response.raise_for_status()
    return response.json()["access_token"]

def fetch_partners(token):
    """Fetch all cross-tenant access policy partners with identity synchronization expanded"""
    # Using Beta API to include groupSyncInbound (Preview feature)
    url = "https://graph.microsoft.com/beta/policies/crossTenantAccessPolicy/partners?$expand=identitySynchronization"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.json()["value"]

def fetch_tenant_info(token, tenant_id):
    """Fetch basic tenant information (name and primary domain)"""
    url = f"https://graph.microsoft.com/v1.0/tenantRelationships/findTenantInformationByTenantId(tenantId='{tenant_id}')"
    headers = {"Authorization": f"Bearer {token}"}
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Warning: Could not fetch info for tenant {tenant_id}: {e}")
        return {}

def map_partner(p, t_info):
    """Map Graph API partner object to peers.yaml structure"""
    peer = {
        "name": t_info.get("displayName") or p.get("displayName") or "Unknown",
        "fqdn": t_info.get("defaultDomainName") or "Unknown",
        "tenant_id": p.get("tenantId")
    }

    inbound = {}
    outbound = {}

    # B2B Collaboration Inbound
    b2b_in = p.get("b2bCollaborationInbound")
    if b2b_in:
        # Use accessType from usersAndGroups or applications (they are usually the same in simple setups)
        access_type = b2b_in.get("usersAndGroups", {}).get("accessType") or b2b_in.get("applications", {}).get("accessType")
        if access_type:
            inbound["b2b_collaboration"] = {"access_type": access_type}

    # B2B Collaboration Outbound
    b2b_out = p.get("b2bCollaborationOutbound")
    if b2b_out:
        access_type = b2b_out.get("usersAndGroups", {}).get("accessType") or b2b_out.get("applications", {}).get("accessType")
        if access_type:
            outbound["b2b_collaboration"] = {"access_type": access_type}

    # Inbound Trust
    trust = p.get("inboundTrust")
    if trust:
        inbound["trust"] = {
            "mfa_accepted": trust.get("isMfaAccepted"),
            "compliant_device_accepted": trust.get("isCompliantDeviceAccepted"),
            "hybrid_azure_ad_joined_device_accepted": trust.get("isHybridAzureADJoinedDeviceAccepted"),
        }

    # Automatic User Consent Settings
    consent = p.get("automaticUserConsentSettings")
    if consent:
        in_consent = consent.get("inboundAllowed")
        out_consent = consent.get("outboundAllowed")
        if in_consent is not None:
            inbound["automatic_user_consent"] = in_consent
        if out_consent is not None:
            outbound["automatic_user_consent"] = out_consent

    # Identity Synchronization
    idsync = p.get("identitySynchronization")
    if idsync:
        user_sync_obj = idsync.get("userSyncInbound")
        group_sync_obj = idsync.get("groupSyncInbound")
        
        user_sync = None
        if user_sync_obj:
            user_sync = user_sync_obj.get("isSyncAllowed") if "isSyncAllowed" in user_sync_obj else user_sync_obj.get("isAllowed")
            
        group_sync = None
        if group_sync_obj:
            group_sync = group_sync_obj.get("isSyncAllowed") if "isSyncAllowed" in group_sync_obj else group_sync_obj.get("isAllowed")

        if user_sync is not None or group_sync is not None:
            inbound["identity_sync"] = {}
            if user_sync is not None:
                inbound["identity_sync"]["user"] = user_sync
            if group_sync is not None:
                inbound["identity_sync"]["group"] = group_sync

    if inbound:
        peer["inbound"] = inbound
    if outbound:
        peer["outbound"] = outbound
    
    # Tenant Restrictions
    restrictions = p.get("tenantRestrictions")
    if restrictions:
         access_type = restrictions.get("usersAndGroups", {}).get("accessType") or restrictions.get("applications", {}).get("accessType")
         if access_type:
             peer["tenant_restrictions"] = {"access_type": access_type}

    return peer

def main():
    # Use environment variables from .envrc (direnv)
    client_id = os.environ.get("ARM_CLIENT_ID")
    client_secret = os.environ.get("ARM_CLIENT_SECRET")
    tenant_id = os.environ.get("ARM_TENANT_ID")

    if not all([client_id, client_secret, tenant_id]):
        print("Error: Missing one of ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID.")
        print("Ensure they are set in your environment (e.g., via direnv).")
        sys.exit(1)

    try:
        print(f"Authenticating with tenant {tenant_id}...")
        token = get_token(client_id, client_secret, tenant_id)
        
        print("Fetching partners from Graph API...")
        partners = fetch_partners(token)
        
        peers_list = []
        for p in partners:
            tid = p.get("tenantId")
            print(f"Processing tenant {tid}...")
            t_info = fetch_tenant_info(token, tid)
            peers_list.append(map_partner(p, t_info))
        
        # Build YAML content with schema reference
        yaml_content = SCHEMA_REF
        yaml_content += yaml.dump(peers_list, sort_keys=False, default_flow_style=False)
        
        # Ensure config directory exists
        os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
        
        with open(CONFIG_PATH, "w") as f:
            f.write(yaml_content)
            
        print(f"Successfully exported {len(peers_list)} partners to {CONFIG_PATH}")

    except requests.exceptions.HTTPError as err:
        print(f"HTTP Error: {err}")
        if err.response.text:
            print(f"Response: {err.response.text}")
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
