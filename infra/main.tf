# --- infra/main.tf ---
#
# 两个区域各创建：
#   1. 1 个企业路由器 (ER) 实例（配额限制：1 个/区域）
#   2. 2 个 ER 路由表（prod + nonprod），实现区域内流量分段
#   3. 4 个 Spoke VPC（2 prod + 2 nonprod），通过 ER VPC 附件接入 ER
#   4. ER 关联与传播 — prod VPC 关联到 prod 路由表，nonprod VPC 关联到 nonprod 路由表
#
# 流量分段原理：
#   - 每个区域内，prod 和 nonprod VPC 分别关联到不同的 ER 路由表
#   - prod 路由表和非prod 路由表之间不互相传播路由 → 区域内隔离
#   - 跨区域分段通过 central-network.tf 中的 CC 中心网络实现
#     CC 策略只关联 prod 路由表 → prod 跨区域连通，nonprod 仅区域内隔离

# ============================================================
# 区域 1：华北-北京四
# ============================================================

# 企业路由器实例
resource "huaweicloud_er_instance" "region1" {
  provider = huaweicloud.region1

  name                           = "${var.identifier}-er-region1"
  asn                            = var.er_asn.region1
  availability_zones             = var.availability_zones.region1
  enable_default_association     = false
  enable_default_propagation     = false
  auto_accept_shared_attachments = false
}

# ER 路由表 — prod
resource "huaweicloud_er_route_table" "region1_prod" {
  provider = huaweicloud.region1

  instance_id = huaweicloud_er_instance.region1.id
  name        = "${var.identifier}-region1-prod-rt"
}

# ER 路由表 — nonprod
resource "huaweicloud_er_route_table" "region1_nonprod" {
  provider = huaweicloud.region1

  instance_id = huaweicloud_er_instance.region1.id
  name        = "${var.identifier}-region1-nonprod-rt"
}

# Spoke VPC（区域 1）
module "region1_vpcs" {
  source   = "./modules/vpc"
  for_each = var.region1_vpcs

  providers = {
    huaweicloud = huaweicloud.region1
  }

  identifier         = var.identifier
  vpc_name           = "region1-${each.key}"
  cidr_block         = each.value.cidr_block
  number_azs         = each.value.number_azs
  availability_zones = var.availability_zones.region1
  er_instance_id     = huaweicloud_er_instance.region1.id
  segment            = each.value.type
}

# ER 关联：prod VPC → prod 路由表
resource "huaweicloud_er_association" "region1_prod" {
  provider = huaweicloud.region1
  for_each = { for k, v in var.region1_vpcs : k => v if v.type == "prod" }

  instance_id    = huaweicloud_er_instance.region1.id
  route_table_id = huaweicloud_er_route_table.region1_prod.id
  attachment_id  = module.region1_vpcs[each.key].er_attachment_id
}

# ER 传播：prod VPC → prod 路由表
resource "huaweicloud_er_propagation" "region1_prod" {
  provider = huaweicloud.region1
  for_each = { for k, v in var.region1_vpcs : k => v if v.type == "prod" }

  instance_id    = huaweicloud_er_instance.region1.id
  route_table_id = huaweicloud_er_route_table.region1_prod.id
  attachment_id  = module.region1_vpcs[each.key].er_attachment_id
}

# ER 关联：nonprod VPC → nonprod 路由表
resource "huaweicloud_er_association" "region1_nonprod" {
  provider = huaweicloud.region1
  for_each = { for k, v in var.region1_vpcs : k => v if v.type == "nonprod" }

  instance_id    = huaweicloud_er_instance.region1.id
  route_table_id = huaweicloud_er_route_table.region1_nonprod.id
  attachment_id  = module.region1_vpcs[each.key].er_attachment_id
}

# ER 传播：nonprod VPC → nonprod 路由表
resource "huaweicloud_er_propagation" "region1_nonprod" {
  provider = huaweicloud.region1
  for_each = { for k, v in var.region1_vpcs : k => v if v.type == "nonprod" }

  instance_id    = huaweicloud_er_instance.region1.id
  route_table_id = huaweicloud_er_route_table.region1_nonprod.id
  attachment_id  = module.region1_vpcs[each.key].er_attachment_id
}

# ============================================================
# 区域 2：华东-上海一
# ============================================================

# 企业路由器实例
resource "huaweicloud_er_instance" "region2" {
  provider = huaweicloud.region2

  name                           = "${var.identifier}-er-region2"
  asn                            = var.er_asn.region2
  availability_zones             = var.availability_zones.region2
  enable_default_association     = false
  enable_default_propagation     = false
  auto_accept_shared_attachments = false
}

# ER 路由表 — prod
resource "huaweicloud_er_route_table" "region2_prod" {
  provider = huaweicloud.region2

  instance_id = huaweicloud_er_instance.region2.id
  name        = "${var.identifier}-region2-prod-rt"
}

# ER 路由表 — nonprod
resource "huaweicloud_er_route_table" "region2_nonprod" {
  provider = huaweicloud.region2

  instance_id = huaweicloud_er_instance.region2.id
  name        = "${var.identifier}-region2-nonprod-rt"
}

# Spoke VPC（区域 2）
module "region2_vpcs" {
  source   = "./modules/vpc"
  for_each = var.region2_vpcs

  providers = {
    huaweicloud = huaweicloud.region2
  }

  identifier         = var.identifier
  vpc_name           = "region2-${each.key}"
  cidr_block         = each.value.cidr_block
  number_azs         = each.value.number_azs
  availability_zones = var.availability_zones.region2
  er_instance_id     = huaweicloud_er_instance.region2.id
  segment            = each.value.type
}

# ER 关联：prod VPC → prod 路由表
resource "huaweicloud_er_association" "region2_prod" {
  provider = huaweicloud.region2
  for_each = { for k, v in var.region2_vpcs : k => v if v.type == "prod" }

  instance_id    = huaweicloud_er_instance.region2.id
  route_table_id = huaweicloud_er_route_table.region2_prod.id
  attachment_id  = module.region2_vpcs[each.key].er_attachment_id
}

# ER 传播：prod VPC → prod 路由表
resource "huaweicloud_er_propagation" "region2_prod" {
  provider = huaweicloud.region2
  for_each = { for k, v in var.region2_vpcs : k => v if v.type == "prod" }

  instance_id    = huaweicloud_er_instance.region2.id
  route_table_id = huaweicloud_er_route_table.region2_prod.id
  attachment_id  = module.region2_vpcs[each.key].er_attachment_id
}

# ER 关联：nonprod VPC → nonprod 路由表
resource "huaweicloud_er_association" "region2_nonprod" {
  provider = huaweicloud.region2
  for_each = { for k, v in var.region2_vpcs : k => v if v.type == "nonprod" }

  instance_id    = huaweicloud_er_instance.region2.id
  route_table_id = huaweicloud_er_route_table.region2_nonprod.id
  attachment_id  = module.region2_vpcs[each.key].er_attachment_id
}

# ER 传播：nonprod VPC → nonprod 路由表
resource "huaweicloud_er_propagation" "region2_nonprod" {
  provider = huaweicloud.region2
  for_each = { for k, v in var.region2_vpcs : k => v if v.type == "nonprod" }

  instance_id    = huaweicloud_er_instance.region2.id
  route_table_id = huaweicloud_er_route_table.region2_nonprod.id
  attachment_id  = module.region2_vpcs[each.key].er_attachment_id
}
