# --- infra/modules/vpc/variables.tf ---

variable "identifier" {
  type        = string
  description = "项目标识符。"
}

variable "vpc_name" {
  type        = string
  description = "VPC 名称。"
}

variable "cidr_block" {
  type        = string
  description = "VPC 的 IPv4 CIDR。"
}

variable "number_azs" {
  type        = number
  description = "使用的可用区数量。"
}

variable "availability_zones" {
  type        = list(string)
  description = "可用区列表。"
}

variable "er_instance_id" {
  type        = string
  description = "企业路由器实例 ID。"
}

variable "segment" {
  type        = string
  description = "VPC 所属分段（prod 或 nonprod）。"
}
