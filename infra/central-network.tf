# --- infra/central-network.tf ---
#
# 云连接 (CC) + 中心网络 — 跨区域流量分段隔离
#
# 架构设计：
#   CC Connection（云连接）提供全局跨区域连通通道
#   CC Central Network（中心网络）承载跨区域路由平面
#   ER 路由表（prod / nonprod）+ CC 策略选择性关联实现分段
#   CC Central Network Policy（中心网络策略）控制路由关联与传播
#
# 流量分段实现（配额约束下的最佳方案）：
#   ER 配额 = 1 个/区域，CC 策略只允许 1 个 planes 块。
#   方案：单个 CC 中央网络，策略只关联 prod 路由表。
#     - prod 路由表接入 CC → prod VPC 跨区域连通
#     - nonprod 路由表不接入 CC → nonprod VPC 仅区域内隔离
#   两个分段在 CC 层面完全隔离：nonprod 路由不可跨区域传播。

# ============================================================
# 云连接（全局跨区域连通）
# ============================================================

resource "huaweicloud_cc_connection" "global" {
  provider = huaweicloud.cc

  name        = "${var.identifier}-cloud-connection"
  description = "Global cloud connection for multi-region traffic segmentation"
}

# ============================================================
# 中心网络（跨区域路由平面）
# ============================================================

resource "huaweicloud_cc_central_network" "main" {
  provider = huaweicloud.cc

  name        = "${var.identifier}-central-network"
  description = "Central network for multi-region traffic segmentation (prod cross-region, nonprod intra-region)"
}

# ============================================================
# 中心网络策略（路由关联与传播控制）
# ============================================================

resource "huaweicloud_cc_central_network_policy" "main" {
  provider = huaweicloud.cc

  central_network_id = huaweicloud_cc_central_network.main.id

  # 注册两个区域的 ER 实例
  er_instances {
    enterprise_router_id = huaweicloud_er_instance.region1.id
    project_id           = var.project_ids.region1
    region_id            = var.hw_regions.region1
  }

  er_instances {
    enterprise_router_id = huaweicloud_er_instance.region2.id
    project_id           = var.project_ids.region2
    region_id            = var.hw_regions.region2
  }

  # 网络平面：只关联 prod 路由表
  # → prod VPC 跨区域连通，nonprod VPC 仅区域内隔离
  planes {
    associate_er_tables {
      enterprise_router_id       = huaweicloud_er_instance.region1.id
      enterprise_router_table_id = huaweicloud_er_route_table.region1_prod.id
      project_id                 = var.project_ids.region1
      region_id                  = var.hw_regions.region1
    }

    associate_er_tables {
      enterprise_router_id       = huaweicloud_er_instance.region2.id
      enterprise_router_table_id = huaweicloud_er_route_table.region2_prod.id
      project_id                 = var.project_ids.region2
      region_id                  = var.hw_regions.region2
    }
  }
}

# 策略执行
resource "huaweicloud_cc_central_network_policy_apply" "main" {
  provider = huaweicloud.cc

  central_network_id = huaweicloud_cc_central_network.main.id
  policy_id          = huaweicloud_cc_central_network_policy.main.id
}
