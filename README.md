# distributed-x-infrastructure-multi-region-traffic-segmentation · 分布式跨区域流量分段基础设施

![License: MIT-0](https://img.shields.io/badge/License-MIT--0-yellow.svg)
> 基于华为云企业路由器 (ER) 和云连接 (CC) 中心网络，实现跨两个区域的 prod / nonprod 流量分段隔离。

## 1. 简介 / Overview

### 简介


本仓库是跨区域流量分段架构的华为云 Terraform 实现。通过企业路由器的路由表关联/传播机制实现区域内分段隔离，通过云连接中心网络实现跨区域分段隔离，最终达到 prod 和 nonprod 两个路由域在区域内和跨区域均完全隔离的目标。

---

## 2. 目录


- [1. 简介 / Overview](#1-简介--overview)
- [2. 目录](#2-目录)
- [3. 架构图](#3-架构图)
- [4. 方案亮点](#4-方案亮点)
- [5. 涉及云服务](#5-涉及云服务)
- [6. 前置条件](#6-前置条件)
- [7. 快速开始](#7-快速开始)
- [8. 分步部署](#8-分步部署)
- [9. 使用方法 / 验证](#9-使用方法--验证)
- [10. 清理资源](#10-清理资源)
- [11. 详细说明](#11-详细说明)
- [12. 依赖](#12-依赖)
- [13. FAQ / 故障排除](#13-faq--故障排除)
- [14. 贡献指南](#14-贡献指南)
- [15. 许可证](#15-许可证)
- [16. 联系方式 / 维护者](#16-联系方式--维护者)

### 目录结构


```
.
├── infra/                          # Terraform 基础设施代码
│   ├── providers.tf                # 华为云多区域 provider 配置
│   ├── variables.tf                # 变量定义
│   ├── main.tf                     # ER 实例 + 路由表 + VPC + 关联/传播
│   ├── central-network.tf          # CC 云连接 + 中心网络 + 策略
│   ├── outputs.tf                  # 输出定义
│   └── modules/vpc/               # VPC 模块
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── docs/                           # 文档
│   ├── architecture.md             # 架构说明
│   └── deployment-guide.md         # 部署指导书
├── LICENSE                         # MIT No Attribution
└── README.md                       # 本文件
```

---

## 3. 架构图

```
区域 1 (cn-north-4)                    区域 2 (cn-east-3)
┌──────────────────────┐              ┌──────────────────────┐
│   ER (ASN 65050)     │              │   ER (ASN 65051)     │
│  ┌────────┐┌───────┐ │              │  ┌────────┐┌───────┐ │
│  │prod RT ││nonprod│ │              │  │prod RT ││nonprod│ │
│  └────────┘└───────┘ │              │  └────────┘└───────┘ │
│  4 VPC (2p+2np)      │              │  4 VPC (2p+2np)      │
└──────────┬───────────┘              └──────────┬───────────┘
           │                                     │
     ┌─────┴─────────────────────────────────────┴─────┐
     │           CC 云连接（全局，单个中心网络）          │
     │  ┌───────────────────────────────────────────┐  │
     │  │ 中心网络策略：仅关联两区域 prod 路由表       │  │
     │  │ nonprod 不接入 CC，仅保留区域内隔离          │  │
     │  └───────────────────────────────────────────┘  │
     └────────────────────────────────────────────────┘
```

---

## 4. 方案亮点

- **区域内分段隔离**：通过 ER 路由表关联/传播机制，prod 和 nonprod 路由表独立运作
- **跨区域分段隔离**：通过单个 CC 中心网络的策略仅关联两个区域的 prod 路由表，实现 prod 跨区域互通；受 CC/ER 配额约束，nonprod 不接入 CC，不跨区域
- **完全隔离**：prod 和 nonprod 两个路由域在区域内和跨区域均完全隔离（nonprod 跨区域连通未实现）

---

## 5. 涉及云服务

| 服务 | 用途 |
|------|------|
| 企业路由器 (ER) | 区域内路由分段与 VPC 互联 |
| 云连接 (CC) | 跨区域连通与中心网络管理 |
| 虚拟私有云 (VPC) | 网络隔离与子网管理 |

---

## 6. 前置条件

- 华为云账号，已开通 ER 和 CC 服务
- 两个区域的项目 ID（cn-north-4 和 cn-east-3）
- Terraform >= 1.3
- 华为云 Terraform Provider >= 1.50

---

## 7. 快速开始

```bash
# 配置凭证
export HW_ACCESS_KEY="your-ak"
export HW_SECRET_KEY="your-sk"

# 配置项目 ID
cat > infra/terraform.tfvars << 'EOF'
project_ids = {
  region1 = "cn-north-4 项目 ID"
  region2 = "cn-east-3 项目 ID"
}
EOF

# 部署
cd infra
terraform init
terraform plan
terraform apply
```

详细步骤请参阅 [部署指导书](docs/deployment-guide.md)。

---

## 8. 分步部署

1. 配置华为云凭证（AK/SK）
2. 填写 `infra/terraform.tfvars` 中的项目 ID
3. 执行 `terraform init` 初始化 provider
4. 执行 `terraform plan` 查看变更计划
5. 执行 `terraform apply` 部署资源

---

## 9. 使用方法 / 验证

### 使用方法


部署完成后，可通过以下方式验证流量隔离：

```bash
# 查询 ER 实例状态
hcloud ER ShowEnterpriseRouter --region cn-north-4 --er_id <er-id>

# 查询路由表
hcloud ER ListEnterpriseRouterRouteTables --region cn-north-4 --er_id <er-id>
```

### 流量隔离矩阵

| 源 → 目标 | 同区域 | 跨区域 |
|-----------|--------|--------|
| prod → prod | ✅ 通 | ✅ 通 |
| prod → nonprod | ❌ 隔离 | ❌ 隔离 |
| nonprod → nonprod | ✅ 通 | ❌ 未实现（nonprod 不接入 CC，仅区域内隔离） |
| nonprod → prod | ❌ 隔离 | ❌ 隔离 |

---

## 10. 清理资源

```bash
cd infra
terraform destroy
```

---

## 11. 详细说明

详见 [架构说明](docs/architecture.md) 和 [部署指导书](docs/deployment-guide.md)。

### 提交者信息


| **创建者** | dgc-git |
| **维护者** | dgc-git |

---

## 12. 依赖

- Terraform >= 1.3
- 华为云 Terraform Provider >= 1.50

---

## 13. FAQ / 故障排除

### FAQ


**Q: 为什么 nonprod 跨区域连通不可用？**
A: CC 中心网络策略只允许 1 个 planes 块，同一 ER 不能注册到多个 Central Network，且 ER 配额为 1 个/区域。

---

## 14. 贡献指南

欢迎提交 Issue 与 PR。当前请遵循仓库内现有目录结构与 Terraform 代码风格（`infra/` 为 IaC 代码、`docs/` 为文档），并在提交前说明变更对应的区域与分段（prod / nonprod）。

---

## 15. 许可证

本项目采用 MIT No Attribution 许可证。详见 [LICENSE](LICENSE)。

---

## 16. 联系方式 / 维护者
| 项 | 内容 |
|---|---|
| **创建者** | [dgc-git](https://github.com/dgc-git) |
| **维护者** | [dgc-git](https://github.com/dgc-git) |
| **联系方式** | GitHub Issues / PR（见[第 14 节](#14-贡献指南)） |
