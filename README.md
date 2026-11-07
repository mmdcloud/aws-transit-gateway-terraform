# AWS Multi-VPC Network with Transit Gateway, Centralized Egress & Open-Source Suricata NVA Inspection

This repository provides a production-grade Terraform configuration deploying an Hub-and-Spoke network architecture in AWS using **AWS Transit Gateway (TGW)**, a **Centralized Egress VPC** with Multi-AZ NAT Gateways, and a **Centralized Inspection VPC** powered by an open-source **Suricata Network Virtual Appliance (NVA)** for deep packet inspection (IDS/IPS).

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
│                                      AWS TRANSIT GATEWAY                                      │
│                                                                                               │
│    [1. Spoke TGW RT]                [2. Post-Inspection TGW RT]          [3. Egress TGW RT]   │
│    • 0.0.0.0/0  -> Inspection       • 0.0.0.0/0   -> Egress NAT          • 10.0.0.0/8         │
│    • 10.0.0.0/8 -> Inspection       • 10.1.0.0/16 -> Spoke 1 VPC             -> Inspection    │
│                                     • 10.2.0.0/16 -> Spoke 2 VPC                              │
│                                     • 10.3.0.0/16 -> Spoke 3 VPC                              │
└───────────────┬───────────────────────────────▲───────────────────────────────┬───────────────┘
                │                               │                               │
                │ (TGW Inspection Attachment - Appliance Mode Enabled)          │
                ▼                               │                               │
┌───────────────────────────────────────────────┴───────────────────────────────▼───────────────┐
│                               Central Inspection VPC (10.200.0.0/16)                          │
│                                                                                               │
│    TGW Dedicated Subnets (10.200.254.0/28) ───[ 0.0.0.0/0 & 10.0.0.0/8 ]───►                  │
│                                                                            │                  │
│                                                   [ Suricata NVA Appliance Module ]           │
│                                                   • Linux Kernel IP Forwarding                │
│                                                   • Stateful iptables conntrack forwarding   │
│                                                   • Suricata Real-Time IDS/IPS Deep Packet    │
│                                                   • Source/Dest Check Disabled                │
│                                                   • AWS Systems Manager (SSM) Managed         │
│                                                                            │                  │
│    Appliance Subnets (10.200.1.0/24) ◄────────[ 0.0.0.0/0 & 10.0.0.0/8 ]───┘                  │
└───────────────────────────────────────────────────────────────────────────────────────────────┘
                ▲                                                               ▲
                │ (TGW Spoke Attachments via dedicated /28 subnets)             │
┌───────────────┴──────────────┐   ┌──────────────────────────────┐   ┌─────────┴──────────────┐
│         Spoke VPC 1          │   │         Spoke VPC 2          │   │         Spoke VPC 3          │
│        (10.1.0.0/16)         │   │        (10.2.0.0/16)         │   │        (10.3.0.0/16)         │
│  Instance 1 (Private Subnet) │   │  Instance 2 (Private Subnet) │   │  Instance 3 (Private Subnet) │
└──────────────────────────────┘   └──────────────────────────────┘   └──────────────────────────────┘
```

---

## Key Architectural Highlights

1. **Centralized Inspection (AWS Well-Architected Pattern)**
   - All East-West (Spoke-to-Spoke) and North-South (Internet Egress/Ingress) traffic is routed through the **Central Inspection VPC** (`10.200.0.0/16`).
   - The Inspection VPC is completely isolated: no Internet Gateway and no NAT Gateways.
2. **Production-Grade Open-Source NVA (Suricata)**
   - Deployed as an EC2 module (`modules/ec2`) running Ubuntu 22.04 LTS with `source_dest_check = false`.
   - **Suricata IDS/IPS Engine**: Real-time multi-threaded intrusion detection and deep packet inspection using automated emerging threat rulesets via `suricata-update`.
   - **Linux Kernel Stateful Forwarding**: Configured with `net.ipv4.ip_forward = 1` and `iptables` connection tracking (`conntrack`) with audit logging (`[NVA-FW-FORWARD]`).
   - Zero marketplace licensing or vendor lock-in fees.
3. **Appliance Mode Support**
   - Enabled (`appliance_mode_support = "enable"`) on both the Inspection VPC Attachment and Egress VPC Attachment.
   - Enforces bidirectional flow symmetry across Availability Zones, ensuring stateful inspection engines and NAT Gateways process both request and response packets without connection drops.
4. **Dedicated `/28` Transit Gateway Subnets**
   - Spoke, Inspection, and Egress VPCs host dedicated `/28` subnets (`intra_subnets`) specifically for TGW ENIs.
   - Prevents IP exhaustion and ensures clean separation of routing policies.
5. **Centralized High Availability Egress**
   - Central Egress VPC (`10.100.0.0/16`) hosting Multi-AZ NAT Gateways (1 per AZ) for scalable outbound internet traffic.
6. **Keyless & Secure Systems Management (SSM)**
   - All EC2 instances (workloads and NVA) are attached to an IAM Instance Profile with `AmazonSSMManagedInstanceCore`.
   - Zero bastion hosts required; secure console access via AWS Systems Manager Session Manager.
7. **Multi-Account & Remote State Ready**
   - Dedicated Terraform bootstrap module (`terraform/bootstrap/`) for S3 remote state storage and DynamoDB state locking.
   - Pre-configured AWS RAM resource share (`ram_principals`) for multi-account AWS Organizations deployment.

---

## Repository Structure

```
.
├── README.md
├── docs/
└── terraform/
    ├── backend.tf                  # Remote S3 backend configuration (state locking)
    ├── bootstrap/                  # Infrastructure for S3 state bucket & DynamoDB lock table
    │   ├── main.tf
    │   └── outputs.tf
    ├── main.tf                     # Core orchestration (VPCs, TGW, NVA, Instances, Routes)
    ├── modules/
    │   ├── ec2/                    # EC2 instance module (Instances 1-3 & Suricata NVA)
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── security-groups/        # Modular security group generator
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── transit-gateway/        # Transit Gateway with 3 route tables & attachments
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   └── vpc/                    # Wrapper around terraform-aws-modules/vpc/aws
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    ├── outputs.tf                  # Exported IPs, VPC IDs, TGW IDs, and Appliance metadata
    ├── provider.tf                 # AWS provider configuration
    ├── scripts/
    │   ├── nva_user_data.sh        # Suricata IDS/IPS, iptables, and kernel forwarding bootstrap
    │   └── user_data.sh            # Workload instance bootstrap (Nginx web server)
    ├── terraform.tfvars            # Subnet CIDRs, AZs, region, and instance types
    └── variables.tf                # Variable declarations and defaults
```

---

## Traffic Flow Details

### 1. North-South Outbound (Workload -> Internet)
1. **Workload EC2** in Spoke VPC private subnet (`10.1.4.X`) makes an outbound request (e.g., `curl https://aws.amazon.com`).
2. Spoke private route table sends `0.0.0.0/0` to the **Transit Gateway**.
3. Packet enters TGW on the Spoke attachment and is evaluated by **`spoke-rt`**.
4. **`spoke-rt`** has route `0.0.0.0/0` pointing to the **Inspection VPC attachment**.
5. Packet enters Inspection VPC via TGW intra subnet; route table sends `0.0.0.0/0` to the **Suricata NVA ENI**.
6. The NVA inspects the payload in real-time, logs the connection, and the Linux kernel forwards it to the appliance subnet.
7. Inspection appliance subnet route table sends `0.0.0.0/0` back to the **Transit Gateway**.
8. Packet re-enters TGW and is evaluated by **`post-inspection-rt`**.
9. **`post-inspection-rt`** sends `0.0.0.0/0` to the **Egress VPC attachment**.
10. Egress VPC private route table sends `0.0.0.0/0` to the **NAT Gateway** in that AZ, which SNATs the packet and routes it through the **Internet Gateway** to the Internet.

### 2. North-South Return (Internet -> Workload)
1. Internet responds to the Elastic IP of the NAT Gateway.
2. NAT Gateway translates destination IP back to `10.1.4.X`.
3. Egress VPC public route table directs `10.0.0.0/8` to the **Transit Gateway**.
4. Packet enters TGW on Egress attachment and is evaluated by **`egress-rt`**.
5. **`egress-rt`** has route `10.0.0.0/8` pointing to the **Inspection VPC attachment** (enforcing return-path inspection).
6. Packet enters Inspection VPC; intra route table sends `10.0.0.0/8` to the **Suricata NVA ENI**.
7. Suricata inspects incoming response packets; Linux kernel forwards packet to the appliance subnet.
8. Appliance subnet route table sends `10.0.0.0/8` back to the **Transit Gateway**.
9. Packet re-enters TGW on Inspection attachment and is evaluated by **`post-inspection-rt`**.
10. **`post-inspection-rt`** matches the propagated Spoke 1 route (`10.1.0.0/16`) and delivers the packet directly to **Spoke VPC 1** and Instance 1.

### 3. East-West Inter-Spoke (Spoke 1 -> Spoke 2)
1. Instance 1 (`10.1.4.X`) sends traffic to Instance 2 (`10.2.4.X`).
2. Spoke 1 private route table sends `0.0.0.0/0` to the **Transit Gateway**.
3. Evaluated by **`spoke-rt`**: matches `10.0.0.0/8` -> routed to **Inspection VPC attachment**.
4. Packet enters Inspection VPC, is steered to **Suricata NVA ENI**, deeply inspected, and forwarded out.
5. Re-enters TGW on Inspection attachment -> evaluated by **`post-inspection-rt`**.
6. **`post-inspection-rt`** matches propagated Spoke 2 route (`10.2.0.0/16`) and delivers the packet to **Spoke VPC 2**.

---

## CIDR & Subnet Allocations

| VPC Name | VPC CIDR | Subnet Purpose | Subnet CIDR Range |
| :--- | :--- | :--- | :--- |
| **VPC 1 (Spoke)** | `10.1.0.0/16` | Public Subnets<br>Private Workload Subnets<br>TGW Attachment (`intra`) | `10.1.1.0/24 - 10.1.3.0/24`<br>`10.1.4.0/24 - 10.1.6.0/24`<br>`10.1.254.0/28 - 10.1.254.32/28` |
| **VPC 2 (Spoke)** | `10.2.0.0/16` | Public Subnets<br>Private Workload Subnets<br>TGW Attachment (`intra`) | `10.2.1.0/24 - 10.2.3.0/24`<br>`10.2.4.0/24 - 10.2.6.0/24`<br>`10.2.254.0/28 - 10.2.254.32/28` |
| **VPC 3 (Spoke)** | `10.3.0.0/16` | Public Subnets<br>Private Workload Subnets<br>TGW Attachment (`intra`) | `10.3.1.0/24 - 10.3.3.0/24`<br>`10.3.4.0/24 - 10.3.6.0/24`<br>`10.3.254.0/28 - 10.3.254.32/28` |
| **Central Egress VPC** | `10.100.0.0/16` | Multi-AZ NAT Gateway Subnets<br>TGW Attachment Subnets (`private`) | `10.100.1.0/24 - 10.100.3.0/24`<br>`10.100.254.0/28 - 10.100.254.32/28` |
| **Central Inspection VPC** | `10.200.0.0/16` | Suricata Appliance Subnets (`private`)<br>TGW Attachment Subnets (`intra`) | `10.200.1.0/24 - 10.200.3.0/24`<br>`10.200.254.0/28 - 10.200.254.32/28` |

---

## Deployment Instructions

### Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with Administrator or Network Administrator privileges
- An existing AWS Key Pair in target region (`ap-south-1`) named `mohitd` (or customize in `main.tf`)

### Step 1: (Optional) Deploy Remote Backend
If you wish to store state remotely in S3 with DynamoDB locking:
```bash
cd terraform/bootstrap
terraform init
terraform apply -auto-approve
```
Then uncomment the `backend "s3"` block in `terraform/backend.tf` with the generated bucket name.

### Step 2: Deploy Network Infrastructure
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
Because all instances use AWS Systems Manager, connect directly without SSH keys or public IPs:
```bash
# Connect to Suricata NVA instance
aws ssm start-session --target $(terraform output -raw nva_instance_id)
```

Inside the NVA instance, execute the pre-installed diagnostic tool:
```bash
sudo /usr/local/bin/check-nva.sh
```

**Expected Output:**
```
==========================================
   Suricata NVA Appliance Status
==========================================
IP Forwarding: 1
Suricata Service: active

--- Recent Suricata IDS/IPS Alerts (/var/log/suricata/fast.log) ---
No threat alerts detected yet. Suricata is monitoring in clean state.

--- Recent Forwarded Connections (iptables) ---
[NVA-FW-FORWARD] IN=eth0 OUT=eth0 SRC=10.1.4.15 DST=10.2.4.22 PROTO=TCP ...
==========================================
```

### 2. Test Centralized Egress Internet Access
Connect to any workload instance (e.g. Instance 1 in Spoke VPC 1):
```bash
aws ssm start-session --target <instance1-id>
```
Test internet connectivity:
```bash
# Verify outbound HTTP/HTTPS through Suricata NVA and Central NAT Gateway
curl -I https://checkip.amazonaws.com
```
The returned IP will match one of the Elastic IPs of the Central Egress VPC NAT Gateways.

### 3. Test Inter-Spoke East-West Connectivity
From Instance 1, test HTTP or ICMP to Instance 2 and Instance 3:
```bash
# Ping Instance 2 in VPC 2
ping -c 3 $(terraform output -raw instance2_private_ip)

# Query Nginx on Instance 3 in VPC 3
curl http://$(terraform output -raw instance3_private_ip)
```

Check the Suricata NVA logs on the NVA machine to observe forwarded flows:
```bash
sudo dmesg | grep "NVA-FW-FORWARD" | tail -n 20
```

---

## Terraform Outputs

Run `terraform output` to view deployment outputs:

| Output Name | Description |
| :--- | :--- |
| `instance1_private_ip` | Private IP of test instance in Spoke VPC 1 |
| `instance2_private_ip` | Private IP of test instance in Spoke VPC 2 |
| `instance3_private_ip` | Private IP of test instance in Spoke VPC 3 |
| `nva_instance_id` | EC2 Instance ID of the Suricata NVA Appliance |
| `nva_private_ip` | Private IP of the Suricata NVA primary network interface |
| `inspection_vpc_id` | VPC ID of the Centralized Inspection VPC |
| `tgw_inspection_attachment_id` | Transit Gateway attachment ID for the Inspection VPC |
| `tgw_post_inspection_route_table_id` | Transit Gateway Post-Inspection Route Table ID |

---

## Teardown

To destroy all deployed resources:
```bash
cd terraform
terraform destroy -auto-approve
```
