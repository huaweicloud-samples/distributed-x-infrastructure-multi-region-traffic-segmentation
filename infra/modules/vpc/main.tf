# --- infra/modules/vpc/main.tf ---

terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.50.0"
    }
  }
}

# VPC
resource "huaweicloud_vpc" "this" {
  name = "${var.identifier}-${var.vpc_name}"
  cidr = var.cidr_block
}

# 子网（每个可用区一个子网）
resource "huaweicloud_vpc_subnet" "this" {
  count = var.number_azs

  name       = "${var.identifier}-${var.vpc_name}-subnet-${count.index + 1}"
  vpc_id     = huaweicloud_vpc.this.id
  cidr       = cidrsubnet(var.cidr_block, 4, count.index)
  gateway_ip = cidrhost(cidrsubnet(var.cidr_block, 4, count.index), 1)
}

# 企业路由器 VPC 附件
# 使用第一个子网作为 ER 附件的连接点
# auto_create_vpc_routes = true 会自动在 VPC 默认路由表中创建指向 ER 的路由
resource "huaweicloud_er_vpc_attachment" "this" {
  name                   = "${var.identifier}-${var.vpc_name}-er-attachment"
  instance_id            = var.er_instance_id
  vpc_id                 = huaweicloud_vpc.this.id
  subnet_id              = huaweicloud_vpc_subnet.this[0].id
  auto_create_vpc_routes = true
}
