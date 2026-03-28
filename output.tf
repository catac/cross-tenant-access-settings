
data "microsoft365wp_cross_tenant_access_policy" "this" {
}

output "tenant_restriction_policy_id" {
  value = data.microsoft365wp_cross_tenant_access_policy.this.id
}
