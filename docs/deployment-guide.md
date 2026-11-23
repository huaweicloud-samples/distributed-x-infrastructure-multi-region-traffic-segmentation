# 部署指导书

## 前置条件

### 1. 华为云环境

- 已注册华为云账号并完成实名认证
- 已获取 AK/SK（访问密钥/秘密访问密钥）
- 账号已开通企业路由器 (ER) 和云连接 (CC) 服务
- 账号在目标区域（cn-north-4、cn-east-3）有足够的配额

### 2. 本地工具

- Terraform >= 1.3.0
- 华为云 Provider >= 1.50.0

可通过以下方式安装 Terraform：

```bash
# 使用华为云镜像安装 Terraform
wget https://mirrors.huaweicloud.com/terraform/1.9.8/terraform_1.9.8_linux_arm64.zip
unzip terraform_1.9.8_linux_arm64.zip
mv terraform /usr/local/bin/
```

### 3. 获取项目 ID

部署前需要获取两个区域的 IAM 项目 ID：

```bash
# 安装华为云命令行工具
pip install hcloud

# 配置凭证
hcloud configure set --ak=YOUR_AK --sk=YOUR_SK --region=cn-north-4

# 获取 cn-north-4 的项目 ID
hcloud IAM ShowProject --cli-region=cn-north-4

# 获取 cn-east-3 的项目 ID
hcloud IAM ShowProject --cli-region=cn-east-3
```

## 部署步骤

### 步骤 1：配置凭证

通过环境变量配置华为云认证信息（推荐，避免凭证写入文件）：

```bash
export HW_ACCESS_KEY="your-access-key"
export HW_SECRET_KEY="your-secret-key"
```

### 步骤 2：配置项目 ID

编辑 `infra/terraform.tfvars`（如不存在则创建）：

```hcl
project_ids = {
  region1 = "cn-north-4 的项目 ID"
  region2 = "cn-east-3 的项目 ID"
}
```

### 步骤 3：初始化 Terraform

```bash
cd infra
terraform init
```

### 步骤 4：预览变更

```bash
terraform plan
```

检查输出，确认将创建的资源符合预期：
- 2 个企业路由器实例
- 4 个 ER 路由表（2 区域 × 2 分段）
- 8 个 VPC（2 区域 × 4 VPC）
- 8 个 ER VPC 附件
- 8 个 ER 关联 + 8 个 ER 传播
- 1 个云连接
- 2 个中心网络 + 2 个中心网络策略 + 2 个策略应用

### 步骤 5：执行部署

```bash
terraform apply
```

输入 `yes` 确认部署。

### 步骤 6：验证部署

```bash
# 查看输出
terraform output

# 验证 ER 实例状态
hcloud ER ShowEnterpriseRouter --instance_id=$(terraform output -raw region1_er_instance_id) --cli-region=cn-north-4
hcloud ER ShowEnterpriseRouter --instance_id=$(terraform output -raw region2_er_instance_id) --cli-region=cn-east-3

# 验证中心网络状态
hcloud CC ShowCentralNetwork --central_network_id=$(terraform output -raw prod_central_network_id) --cli-region=cn-north-4
hcloud CC ShowCentralNetwork --central_network_id=$(terraform output -raw nonprod_central_network_id) --cli-region=cn-north-4
```

## 验证流量分段

### 在 VPC 中创建测试 ECS

在每个 VPC 中创建一台 ECS 实例，然后通过 ping 测试连通性：

| 测试场景 | 预期结果 |
|---------|---------|
| prod-1 → prod-2（同区域） | 通 |
| prod-1 → prod-2（跨区域） | 通 |
| prod-1 → non-prod-1（同区域） | 不通 |
| prod-1 → non-prod-1（跨区域） | 不通 |
| non-prod-1 → non-prod-2（同区域） | 通 |
| non-prod-1 → non-prod-2（跨区域） | 通 |

## 清理

```bash
cd infra
terraform destroy
```

输入 `yes` 确认销毁所有资源。

## 常见问题

### Q: terraform apply 报错 "project_id not found"

A: 确保已在 `terraform.tfvars` 中正确配置了两个区域的项目 ID。项目 ID 可通过华为云控制台或命令行工具获取。

### Q: ER 实例创建失败

A: 检查目标区域是否已开通企业路由器服务，以及可用区是否支持 ER。可在华为云控制台 → 企业路由器 → 开通服务中检查。

### Q: CC 中心网络策略应用失败

A: 确保两个区域的 ER 实例状态均为 available，且 ER 路由表已创建。中心网络策略需要引用已存在的 ER 资源。

### Q: 跨区域路由不通

A: 检查中心网络策略是否已成功应用。可通过 `hcloud CC ShowCentralNetworkPolicy` 查看策略状态，确保 `is_applied` 为 true。
