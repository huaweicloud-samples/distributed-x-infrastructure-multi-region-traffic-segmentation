# --- infra/providers.tf ---

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.50.0"
    }
  }
}

# 区域 1：华北-北京四
provider "huaweicloud" {
  region = var.hw_regions.region1
  alias  = "region1"
}

# 区域 2：华东-上海一
provider "huaweicloud" {
  region = var.hw_regions.region2
  alias  = "region2"
}

# Cloud Connection 服务使用区域 1 的 provider
provider "huaweicloud" {
  region = var.hw_regions.region1
  alias  = "cc"
}
