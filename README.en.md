# distributed-x-infrastructure-multi-region-traffic-segmentation

![License: MIT-0](https://img.shields.io/badge/License-MIT--0-yellow.svg)

> Cross-region prod / nonprod traffic segmentation implemented with Huawei Cloud Enterprise Router (ER) and Cloud Connect (CC) Central Network.

## 1. Overview

This repository is a Huawei Cloud Terraform implementation of a cross-region traffic segmentation architecture. Intra-region segmentation is achieved through Enterprise Router route table association and propagation; cross-region segmentation is achieved through the Cloud Connect Central Network. The result is that the prod and nonprod routing domains are completely isolated both within each region and across regions.

## 2. Table of Contents

- [1. Overview](#1-overview)
- [2. Table of Contents](#2-table-of-contents)
- [3. Architecture Diagram](#3-architecture-diagram)
- [4. Highlights](#4-highlights)
- [5. Cloud Services Used](#5-cloud-services-used)
- [6. Prerequisites](#6-prerequisites)
- [7. Quick Start](#7-quick-start)
- [8. Step-by-Step Deployment](#8-step-by-step-deployment)
- [9. Usage / Verification](#9-usage--verification)
- [10. Cleanup](#10-cleanup)
- [11. Detailed Explanation](#11-detailed-explanation)
- [12. Dependencies](#12-dependencies)
- [13. FAQ / Troubleshooting](#13-faq--troubleshooting)
- [14. Contributing](#14-contributing)
- [15. License](#15-license)
- [16. Contact / Maintainers](#16-contact--maintainers)

### Repository Layout

```
.
├── infra/                          # Terraform infrastructure code
│   ├── providers.tf                # Huawei Cloud multi-region provider configuration
│   ├── variables.tf                # Variable definitions
│   ├── main.tf                     # ER instance + route tables + VPCs + associations/propagations
│   ├── central-network.tf          # CC Cloud Connect + Central Network + policies
│   ├── outputs.tf                  # Output definitions
│   └── modules/vpc/               # VPC module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── docs/                           # Documentation
│   ├── architecture.md             # Architecture description
│   └── deployment-guide.md         # Deployment guide
├── LICENSE                         # MIT No Attribution
└── README.md                       # This file
```

## 3. Architecture Diagram

```
Region 1 (cn-north-4)                    Region 2 (cn-east-3)
┌──────────────────────┐              ┌──────────────────────┐
│   ER (ASN 65050)     │              │   ER (ASN 65051)     │
│  ┌────────┐┌───────┐ │              │  ┌────────┐┌───────┐ │
│  │prod RT ││nonprod│ │              │  │prod RT ││nonprod│ │
│  └────────┘└───────┘ │              │  └────────┘└───────┘ │
│  4 VPC (2p+2np)      │              │  4 VPC (2p+2np)      │
└──────────┬───────────┘              └──────────┬───────────┘
           │                                     │
     ┌─────┴─────────────────────────────────────┴─────┐
     │       CC Cloud Connect (global, single Central Network) │
     │  ┌───────────────────────────────────────────┐  │
     │  │ Policy associates prod route tables only  │  │
     │  │ nonprod is not in CC, intra-region only    │  │
     │  └───────────────────────────────────────────┘  │
     └────────────────────────────────────────────────┘
```

## 4. Highlights

- **Intra-region segmentation**: through ER route table association/propagation, the prod and nonprod route tables operate independently
- **Cross-region segmentation**: a single CC Central Network policy associates only the prod route tables of both regions to enable prod cross-region connectivity; due to CC/ER quota constraints, nonprod is not connected to CC and does not span regions
- **Complete isolation**: the prod and nonprod routing domains are completely isolated both within each region and across regions (nonprod cross-region connectivity is a known degradation and is not implemented)

## 5. Cloud Services Used

| Service | Purpose |
|------|------|
| Enterprise Router (ER) | Intra-region routing segmentation and VPC interconnection |
| Cloud Connect (CC) | Cross-region connectivity and Central Network management |
| Virtual Private Cloud (VPC) | Network isolation and subnet management |

## 6. Prerequisites

- A Huawei Cloud account with the ER and CC services enabled
- Project IDs for the two regions (cn-north-4 and cn-east-3)
- Terraform >= 1.3
- Huawei Cloud Terraform Provider >= 1.50

## 7. Quick Start

```bash
# Configure credentials
export HW_ACCESS_KEY="your-ak"
export HW_SECRET_KEY="your-sk"

# Configure project IDs
cat > infra/terraform.tfvars << 'EOF'
project_ids = {
  region1 = "cn-north-4 project ID"
  region2 = "cn-east-3 project ID"
}
EOF

# Deploy
cd infra
terraform init
terraform plan
terraform apply
```

For detailed steps, see the [deployment guide](docs/deployment-guide.md).

## 8. Step-by-Step Deployment

1. Configure Huawei Cloud credentials (AK/SK)
2. Fill in the project IDs in `infra/terraform.tfvars`
3. Run `terraform init` to initialize the providers
4. Run `terraform plan` to review the change plan
5. Run `terraform apply` to deploy the resources

## 9. Usage / Verification

After deployment, verify traffic isolation in the following ways:

```bash
# Query the ER instance status
hcloud ER ShowEnterpriseRouter --region cn-north-4 --er_id <er-id>

# Query the route tables
hcloud ER ListEnterpriseRouterRouteTables --region cn-north-4 --er_id <er-id>
```

### Traffic Isolation Matrix

| Source → Target | Same Region | Cross Region |
|-----------|--------|--------|
| prod → prod | ✅ Connected | ✅ Connected |
| prod → nonprod | ❌ Isolated | ❌ Isolated |
| nonprod → nonprod | ✅ Connected | ❌ Not implemented (nonprod is not in CC, intra-region only) |
| nonprod → prod | ❌ Isolated | ❌ Isolated |

After deployment, follow these steps to verify that the business functionality works before considering the delivery complete.

## 10. Cleanup

```bash
cd infra
terraform destroy
```

## 11. Detailed Explanation

See the [architecture description](docs/architecture.md) and the [deployment guide](docs/deployment-guide.md).

### Contributor Information

| **Creator** | dgc-git |
| **Maintainer** | dgc-git |

## 12. Dependencies

- Terraform >= 1.3
- Huawei Cloud Terraform Provider >= 1.50

## 13. FAQ / Troubleshooting

**Q: Why is nonprod cross-region connectivity unavailable?**
A: The CC Central Network policy allows only one `planes` block; the same ER cannot be registered to multiple Central Networks, and the ER quota is 1 per region.

## 14. Contributing

Issues and PRs are welcome. Please follow the repository's existing directory structure and Terraform code style (`infra/` for IaC, `docs/` for documentation), and describe in your submission which region and segment (prod / nonprod) the change concerns.

## 15. License

This project is licensed under MIT No Attribution. See [LICENSE](LICENSE).

## 16. Contact / Maintainers
| Item | Content |
|---|---|
| **Creator** | [dgc-git](https://github.com/dgc-git) |
| **Maintainer** | [dgc-git](https://github.com/dgc-git) |
| **Contact** | GitHub Issues / PR (see [Section 14](#14-contributing)) |
