# --- infra/variables.tf ---

# 项目标识符
variable "identifier" {
  type        = string
  description = "项目标识符，用于资源命名。"

  default = "traffic-segmentation-er-cc"
}

# 华为云区域配置
variable "hw_regions" {
  type        = map(string)
  description = "华为云区域。"

  default = {
    region1 = "cn-north-4"
    region2 = "cn-east-3"
  }
}

# 企业路由器的 ASN
variable "er_asn" {
  type        = map(number)
  description = "各区域企业路由器的 ASN。"

  default = {
    region1 = 65050
    region2 = 65051
  }
}

# 可用区配置
variable "availability_zones" {
  type        = map(list(string))
  description = "各区域使用的可用区列表。"

  default = {
    region1 = ["cn-north-4a", "cn-north-4g"]
    region2 = ["cn-east-3a", "cn-east-3c"]
  }
}

# 区域 1 的 Spoke VPC 定义
variable "region1_vpcs" {
  type        = any
  description = "区域 1 创建的 VPC 信息。"

  default = {
    "prod-1" = {
      type       = "prod"
      number_azs = 2
      cidr_block = "10.10.0.0/24"
    }
    "prod-2" = {
      type       = "prod"
      number_azs = 2
      cidr_block = "10.0.1.0/24"
    }
    "non-prod-1" = {
      type       = "nonprod"
      number_azs = 2
      cidr_block = "10.0.2.0/24"
    }
    "non-prod-2" = {
      type       = "nonprod"
      number_azs = 2
      cidr_block = "10.10.3.0/24"
    }
  }
}

# 区域 2 的 Spoke VPC 定义
variable "region2_vpcs" {
  type        = any
  description = "区域 2 创建的 VPC 信息。"

  default = {
    "prod-1" = {
      type       = "prod"
      number_azs = 2
      cidr_block = "10.1.0.0/24"
    }
    "prod-2" = {
      type       = "prod"
      number_azs = 2
      cidr_block = "10.1.1.0/24"
    }
    "non-prod-1" = {
      type       = "nonprod"
      number_azs = 2
      cidr_block = "10.1.2.0/24"
    }
    "non-prod-2" = {
      type       = "nonprod"
      number_azs = 2
      cidr_block = "10.1.3.0/24"
    }
  }
}

# 项目 ID（各区域 IAM 项目 ID，用于 CC 中心网络策略）
# 可通过 hcloud IAM GetProject 或华为云控制台获取
variable "project_ids" {
  type        = map(string)
  description = "各区域的 IAM 项目 ID，用于云连接中心网络策略。请替换为实际项目 ID。"

  default = {
    region1 = "REPLACE_WITH_REGION1_PROJECT_ID"
    region2 = "REPLACE_WITH_REGION2_PROJECT_ID"
  }
}
