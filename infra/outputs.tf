# --- infra/outputs.tf ---

# ============================================================
# 企业路由器
# ============================================================

output "region1_er_instance_id" {
  description = "区域 1 企业路由器实例 ID"
  value       = huaweicloud_er_instance.region1.id
}

output "region2_er_instance_id" {
  description = "区域 2 企业路由器实例 ID"
  value       = huaweicloud_er_instance.region2.id
}

output "region1_er_route_tables" {
  description = "区域 1 ER 路由表 ID（prod / nonprod）"
  value = {
    prod    = huaweicloud_er_route_table.region1_prod.id
    nonprod = huaweicloud_er_route_table.region1_nonprod.id
  }
}

output "region2_er_route_tables" {
  description = "区域 2 ER 路由表 ID（prod / nonprod）"
  value = {
    prod    = huaweicloud_er_route_table.region2_prod.id
    nonprod = huaweicloud_er_route_table.region2_nonprod.id
  }
}

# ============================================================
# VPC
# ============================================================

output "region1_vpc_ids" {
  description = "区域 1 VPC ID 列表"
  value       = { for k, v in module.region1_vpcs : k => v.vpc_id }
}

output "region2_vpc_ids" {
  description = "区域 2 VPC ID 列表"
  value       = { for k, v in module.region2_vpcs : k => v.vpc_id }
}

output "region1_er_attachment_ids" {
  description = "区域 1 ER VPC 附件 ID 列表"
  value       = { for k, v in module.region1_vpcs : k => v.er_attachment_id }
}

output "region2_er_attachment_ids" {
  description = "区域 2 ER VPC 附件 ID 列表"
  value       = { for k, v in module.region2_vpcs : k => v.er_attachment_id }
}

# ============================================================
# 云连接 / 中心网络
# ============================================================

output "cloud_connection_id" {
  description = "云连接 ID"
  value       = huaweicloud_cc_connection.global.id
}

output "central_network_id" {
  description = "中心网络 ID"
  value       = huaweicloud_cc_central_network.main.id
}

output "central_network_policy_id" {
  description = "中心网络策略 ID"
  value       = huaweicloud_cc_central_network_policy.main.id
}
