# AWS Multi-Region Multi-VPC Network with Transit Gateway Peering, Centralized Egress & Suricata NVA Inspection

This repository provides a production-grade Terraform configuration deploying an enterprise Hub-and-Spoke and **Inter-Region Peering** network architecture in AWS using **AWS Transit Gateway (TGW)** across `us-east-1` (Primary Hub) and `us-west-2` (Peer/DR Region), a **Centralized Egress VPC** with Multi-AZ NAT Gateways, and a **Centralized Inspection VPC** powered by an open-source **Suricata Network Virtual Appliance (NVA)** for deep packet inspection (IDS/IPS).

---

## Architecture Overview

```
                                  ┌───────────────────────────┐
                                  │      Internet Gateway     │
                                  └─────────────▲─────────────┘
                                                │
                                  ┌─────────────▼─────────────┐
                                  │    Central Egress VPC     │
                                  │       10.100.0.0/16       │
                                  │   Multi-AZ NAT Gateways   │
                                  └─────────────▲─────────────┘
                                                │ (TGW Egress Attachment - Appliance Mode)
┌───────────────────────────────────────────────▼───────────────────────────────────────────────┐
│                            PRIMARY AWS TRANSIT GATEWAY (us-east-1, ASN 64512)                 │
│                                                                                               │
│  [1. Spoke TGW RT]      [2. Post-Inspection RT]       [3. Egress RT]      [4. Peering RT]     │
│  • 0.0.0.0/0  -> Insp   • 0.0.0.0/0   -> Egress NAT   • 10.0.0.0/8        • 10.1-3.0/16 ->Insp│
│  • 10.0.0.0/8 -> Insp   • 10.1.0.0/16 -> VPC 1           -> Insp          • 0.0.0.0/0 -> Insp │
│                         • 10.2.0.0/16 -> VPC 2                            • Blackhole 10.4/16,│
│                         • 10.3.0.0/16 -> VPC 3                              10.100/16,10.200/16
│                         • 10.4.0.0/16 -> Peering Link                                         │
└──────────┬────────────────────────▲───────────────────────────────▲──────────────▲────────────┘
           │ (Inspection Attach)    │                               │              │
           ▼                        │                               │              │ Inter-Region
┌──────────┴────────────────────────┴───────────┐                   │              │ TGW Peering
│    Central Inspection VPC (10.200.0.0/16)     │                   │              │ (Encrypted)
│                                               │                   │              │
│   TGW /28 Subnets ──► [ Suricata NVA ]        │                   │              ▼
│   Appliance Subnets ◄── (iptables + IDS/IPS)  │                   │  ┌────────────────────────┐
└───────────────────────────────────────────────┘                   │  │ PEER TGW (us-west-2)   │
           ▲                                  ▲                     │  │       ASN 64513        │
           │ (TGW Spoke Attachments)          │                     │  │ • peer-spoke-rt        │
┌──────────┴──────────┐   ┌───────────────────┴───┐   ┌─────────────┴┐ │ • peer-peering-rt      │
│    Spoke VPC 1      │   │     Spoke VPC 2       │   │ Spoke VPC 3  │ └───────────▲────────────┘
│   (10.1.0.0/16)     │   │    (10.2.0.0/16)      │   │(10.3.0.0/16) │             │
│  Instance 1 (Priv)  │   │   Instance 2 (Priv)   │   │Instance 3    │ ┌───────────┴────────────┐
└─────────────────────┘   └───────────────────────┘   └──────────────┘ │  Peer Spoke VPC 4      │
                                                                       │  vpc4-peer (10.4/16)   │
                                                                       │  instance4-peer (Priv) │
                                                                       └────────────────────────┘
```

---

## Key Architectural Highlights

1. **Inter-Region Transit Gateway Peering (`us-east-1` ↔ `us-west-2`)**
   - Peered Primary TGW (`ASN 64512` in `us-east-1`) with Peer TGW (`ASN 64513` in `us-west-2`) using `aws_ec2_transit_gateway_peering_attachment` and `aws_ec2_transit_gateway_peering_attachment_accepter`.
   - Separate isolated TGW routing domains on both sides (`primary-peering-rt`, `peer-spoke-rt`, `peer-peering-rt`) with explicit blackhole protection on infrastructure and return CIDRs to eliminate routing loops.
   - All cross-region East-West traffic between `us-east-1` (`10.1.0.0/16`–`10.3.0.0/16`) and `us-west-2` (`10.4.0.0/16`) passes symmetrically through the **Suricata NVA Inspection VPC**.
2. **Centralized Inspection (AWS Well-Architected Pattern)**
   - All intra-region East-West, cross-region Peering, and North-South (Internet Egress/Ingress) traffic is routed through the **Central Inspection VPC** (`10.200.0.0/16`).
   - The Inspection VPC is completely isolated: no Internet Gateway and no NAT Gateways.
3. **Production-Grade Open-Source NVA (Suricata)**
   - Deployed as an EC2 module (`modules/ec2`) running Ubuntu 22.04 LTS with `source_dest_check = false`.
   - **Suricata IDS/IPS Engine**: Real-time multi-threaded intrusion detection and deep packet inspection using automated emerging threat rulesets via `suricata-update`.
   - **Linux Kernel Stateful Forwarding**: Configured with `net.ipv4.ip_forward = 1` and `iptables` connection tracking (`conntrack`) with audit logging (`[NVA-FW-FORWARD]`).
4. **Appliance Mode Support**
   - Enabled (`appliance_mode_support = "enable"`) on both the Inspection VPC Attachment and Egress VPC Attachment to enforce bidirectional flow symmetry across Availability Zones.
5. **Dedicated `/28` Transit Gateway Subnets**
   - All Spoke VPCs (`vpc1`, `vpc2`, `vpc3`, `vpc4-peer`), Inspection VPC, and Egress VPC host dedicated `/28` subnets (`intra_subnets`) specifically for TGW ENIs.
6. **Centralized High Availability Egress**
   - Central Egress VPC (`10.100.0.0/16`) hosting Multi-AZ NAT Gateways (1 per AZ) serving both local (`us-east-1`) and peered (`us-west-2`) spokes through central inspection.
7. **Keyless & Secure Systems Management (SSM)**
   - All EC2 instances across both regions (workloads, NVA, and `instance4-peer`) share the global IAM Instance Profile with `AmazonSSMManagedInstanceCore`.
8. **Multi-Account & Remote State Ready**
   - Dedicated Terraform bootstrap module (`terraform/bootstrap/`) for S3 remote state storage and DynamoDB state locking, plus AWS RAM resource share scaffolding (`ram_principals`).

---

## Repository Structure

```
.
├── README.md
├── docs/
└── terraform/
    ├── backend.tf                      # Remote S3 backend configuration (state locking)
    ├── bootstrap/                      # Infrastructure for S3 state bucket & DynamoDB lock table
    │   ├── main.tf
    │   └── outputs.tf
    ├── main.tf                         # Core multi-region orchestration (VPCs, TGWs, NVA, Routes)
    ├── modules/
    │   ├── ec2/                        # EC2 instance module (Instances 1-3, Peer Instance & NVA)
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   ├── variables.tf
    │   │   └── versions.tf
    │   ├── security-groups/            # Modular security group generator
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   ├── variables.tf
    │   │   └── versions.tf
    │   ├── transit-gateway/            # Primary Transit Gateway with 3 route tables & attachments
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   ├── variables.tf
    │   │   └── versions.tf
    │   ├── transit-gateway-peering/    # Peer TGW, Inter-Region Peering Attachment & Route Tables
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   ├── variables.tf
    │   │   └── versions.tf
    │   └── vpc/                        # Wrapper around terraform-aws-modules/vpc/aws
    │       ├── main.tf
    │       ├── outputs.tf
    │       ├── variables.tf
    │       └── versions.tf
    ├── outputs.tf                      # Exported IPs, VPC IDs, TGW IDs, and Peering metadata
    ├── provider.tf                     # AWS providers (default primary region + aws.peer alias)
    ├── scripts/
    │   ├── nva_user_data.sh            # Suricata IDS/IPS, iptables, and kernel forwarding bootstrap
    │   └── user_data.sh                # Workload instance bootstrap (Nginx web server)
    ├── terraform.tfvars                # Subnet CIDRs, AZs, regions, ASNs, and instance types
    └── variables.tf                    # Variable declarations and defaults
```

---

## Traffic Flow Details

### 1. North-South Outbound (Workload -> Internet)
1. **Workload EC2** in Spoke VPC private subnet (`10.1.4.X`) makes an outbound request.
2. Spoke private route table sends `0.0.0.0/0` to the **Primary TGW**.
3. **`spoke-rt`** matches `0.0.0.0/0` → **Inspection VPC attachment**.
4. Inspection intra route table sends `0.0.0.0/0` → **Suricata NVA ENI**; Suricata inspects and forwards packet to appliance subnet (`0.0.0.0/0` → Primary TGW).
5. **`post-inspection-rt`** matches `0.0.0.0/0` → **Egress VPC attachment** → Multi-AZ **NAT Gateway** → **Internet Gateway** → Internet.

### 2. North-South Return (Internet -> Workload)
1. NAT Gateway translates return packet destination back to `10.1.4.X` (or `10.4.4.X` for Peer Region).
2. Egress VPC public route table directs `10.0.0.0/8` → **Primary TGW**.
3. **`egress-rt`** routes `10.0.0.0/8` → **Inspection VPC attachment** (enforcing return-path inspection).
4. Suricata inspects incoming response and forwards back to Primary TGW (`post-inspection-rt`).
5. **`post-inspection-rt`** delivers packet to `vpc1` (`10.1.0.0/16`) or across the **Peering Link** (`10.4.0.0/16`) to `vpc4-peer`.

### 3. Intra-Region East-West (Spoke 1 -> Spoke 2)
1. Instance 1 (`10.1.4.X`) sends traffic to Instance 2 (`10.2.4.X`).
2. **`spoke-rt`** matches `10.0.0.0/8` → **Inspection VPC attachment** → **Suricata NVA**.
3. After inspection, **`post-inspection-rt`** matches propagated `10.2.0.0/16` → **Spoke VPC 2**.

### 4. Cross-Region Inter-TGW Peering (`us-east-1` ↔ `us-west-2`)
1. **Forward (`10.1.4.X` → `10.4.4.Y`)**:
   - `vpc1` → Primary TGW **`spoke-rt`** (`10.0.0.0/8` → Inspection) → **Suricata NVA** inspects & forwards → Primary TGW **`post-inspection-rt`** (`10.4.0.0/16` → **Peering Attachment**) → encrypted AWS backbone → Peer TGW **`peer-peering-rt`** (propagated `10.4.0.0/16`) → `vpc4-peer`.
2. **Return (`10.4.4.Y` → `10.1.4.X`)**:
   - `vpc4-peer` → Peer TGW **`peer-spoke-rt`** (`10.1.0.0/16` → **Peering Attachment**) → Primary TGW **`primary-peering-rt`** (`10.1.0.0/16` → Inspection) → **Suricata NVA** inspects return flow → Primary TGW **`post-inspection-rt`** (`10.1.0.0/16`) → `vpc1`.

---

## CIDR & Subnet Allocations

| VPC Name | Region | VPC CIDR | Subnet Purpose | Subnet CIDR Range |
| :--- | :--- | :--- | :--- | :--- |
| **VPC 1 (Spoke)** | `us-east-1` | `10.1.0.0/16` | Public Subnets<br>Private Workload Subnets<br>TGW Attachment (`intra`) | `10.1.1.0/24 - 10.1.3.0/24`<br>`10.1.4.0/24 - 10.1.6.0/24`<br>`10.1.254.0/28 - 10.1.254.32/28` |
| **VPC 2 (Spoke)** | `us-east-1` | `10.2.0.0/16` | Public Subnets<br>Private Workload Subnets<br>TGW Attachment (`intra`) | `10.2.1.0/24 - 10.2.3.0/24`<br>`10.2.4.0/24 - 10.2.6.0/24`<br>`10.2.254.0/28 - 10.2.254.32/28` |
| **VPC 3 (Spoke)** | `us-east-1` | `10.3.0.0/16` | Public Subnets<br>Private Workload Subnets<br>TGW Attachment (`intra`) | `10.3.1.0/24 - 10.3.3.0/24`<br>`10.3.4.0/24 - 10.3.6.0/24`<br>`10.3.254.0/28 - 10.3.254.32/28` |
| **Central Egress VPC** | `us-east-1` | `10.100.0.0/16` | Multi-AZ NAT Gateway Subnets<br>TGW Attachment Subnets (`private`) | `10.100.1.0/24 - 10.100.3.0/24`<br>`10.100.254.0/28 - 10.100.254.32/28` |
| **Central Inspection VPC** | `us-east-1` | `10.200.0.0/16` | Suricata Appliance Subnets (`private`)<br>TGW Attachment Subnets (`intra`) | `10.200.1.0/24 - 10.200.3.0/24`<br>`10.200.254.0/28 - 10.200.254.32/28` |
| **VPC 4 (`vpc4-peer`)** | `us-west-2` | `10.4.0.0/16` | Public Subnets<br>Private Workload Subnets<br>TGW Attachment (`intra`) | `10.4.1.0/24 - 10.4.3.0/24`<br>`10.4.4.0/24 - 10.4.6.0/24`<br>`10.4.254.0/28 - 10.4.254.32/28` |

---

## Deployment Instructions

### Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with Administrator or Network Administrator privileges across `us-east-1` and `us-west-2`
- An existing AWS Key Pair in `us-east-1` named `mohitd` (or customize in `main.tf`; the Peer Region instance uses keyless SSM Session Manager)

### Step 1: (Optional) Deploy Remote Backend
If you wish to store state remotely in S3 with DynamoDB locking:
```bash
cd terraform/bootstrap
terraform init
terraform apply -auto-approve
```
Then uncomment the `backend "s3"` block in `terraform/backend.tf` with the generated bucket name.

### Step 2: Deploy Multi-Region Network Infrastructure
```bash
cd terraform

# 1. Initialize Terraform plugins and modules
terraform init

# 2. Validate configuration syntax
terraform validate

# 3. Review planned resources
terraform plan

# 4. Apply configuration
terraform apply
```

---

## Verification & Operational Testing

### 1. Verify Suricata NVA Status via AWS SSM
Connect directly without SSH keys or public IPs:
```bash
# Connect to Suricata NVA instance in us-east-1
aws ssm start-session --region us-east-1 --target $(terraform output -raw nva_instance_id)
```

Inside the NVA instance, run the pre-installed diagnostic tool:
```bash
sudo /usr/local/bin/check-nva.sh
```

### 2. Test Cross-Region TGW Peering & Inspection
Connect to the Peer Region test instance (`instance4-peer` in `us-west-2`):
```bash
aws ssm start-session --region us-west-2 --target $(terraform output -raw peer_instance_id)
```
From `instance4-peer` (`10.4.4.X`), test cross-region ICMP, Nginx HTTP, and centralized internet egress:
```bash
# 1. Cross-region ping & HTTP to Instance 1 in us-east-1 (passes through Suricata NVA)
ping -c 3 $(terraform output -raw instance1_private_ip)
curl http://$(terraform output -raw instance1_private_ip)

# 2. Verify centralized egress NAT from us-west-2 through us-east-1 Inspection & Egress VPC
curl -I https://checkip.amazonaws.com
```
On the NVA machine (`us-east-1`), inspect forwarded cross-region packets:
```bash
sudo dmesg | grep "NVA-FW-FORWARD" | tail -n 20
```

---

## Terraform Outputs

Run `terraform output` to view deployment outputs:

| Output Name | Description |
| :--- | :--- |
| `instance1_private_ip` | Private IP of test instance in Spoke VPC 1 (`us-east-1`) |
| `instance2_private_ip` | Private IP of test instance in Spoke VPC 2 (`us-east-1`) |
| `instance3_private_ip` | Private IP of test instance in Spoke VPC 3 (`us-east-1`) |
| `peer_instance_id` | EC2 Instance ID of `instance4-peer` (`us-west-2`) |
| `peer_instance_private_ip` | Private IP of `instance4-peer` in Peer Spoke VPC 4 (`us-west-2`) |
| `nva_instance_id` | EC2 Instance ID of the Suricata NVA Appliance (`us-east-1`) |
| `nva_private_ip` | Private IP of the Suricata NVA primary network interface |
| `inspection_vpc_id` | VPC ID of the Centralized Inspection VPC |
| `tgw_inspection_attachment_id` | Transit Gateway attachment ID for the Inspection VPC |
| `tgw_post_inspection_route_table_id` | Transit Gateway Post-Inspection Route Table ID |
| `peer_vpc_id` | VPC ID of Peer Spoke VPC 4 (`vpc4-peer` in `us-west-2`) |
| `peer_transit_gateway_id` | Transit Gateway ID in the Peer Region (`us-west-2`) |
| `tgw_peering_attachment_id` | Inter-Region Transit Gateway Peering Attachment ID |
| `tgw_primary_peering_route_table_id` | Primary Region TGW Peering Route Table ID |
| `tgw_peer_spoke_route_table_id` | Peer Region TGW Spoke Route Table ID |

---

## Teardown

To destroy all deployed resources across both regions:
```bash
cd terraform
terraform destroy -auto-approve
```
