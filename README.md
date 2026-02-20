# **Terraform Cloud Infrastructure Automation Project**

## **Project 401: Migrating Infrastructure to Terraform Cloud with Packer and Ansible Integration**

---

## **📋 Project Overview**

This project demonstrates the complete migration of an existing Terraform codebase to **Terraform Cloud**, a managed service that provides remote state management, team collaboration, and automated infrastructure provisioning. The project integrates **Packer** for custom AMI creation and **Ansible** for configuration management, following industry best practices for immutable infrastructure and Infrastructure as Code (IaC).

### **Why Terraform Cloud?**

| Challenge                    | Solution with Terraform Cloud           |
| ---------------------------- | --------------------------------------- |
| Local state file management  | Remote state storage with versioning    |
| Team collaboration conflicts | State locking with DynamoDB             |
| Manual plan/apply execution  | Automated VCS-driven workflows          |
| Environment inconsistencies  | Workspace isolation                     |
| Limited visibility           | Complete audit trails and notifications |

---

## **🏗️ Architecture Overview**

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                         │
│            (dev/test/prod branches with Terraform code)         │
└─────────────────────────┬───────────────────────────────────────┘
                          │ Push / PR
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Terraform Cloud                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    Workspaces                             │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐               │   │
│  │  │   dev    │  │   test   │  │   prod   │               │   │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘               │   │
│  │       │             │             │                      │   │
│  │       └─────────────┼─────────────┘                      │   │
│  │                     │                                     │   │
│  │            ┌────────▼────────┐                           │   │
│  │            │  Remote State    │                           │   │
│  │            │  + Locking       │                           │   │
│  │            └────────┬────────┘                           │   │
│  └─────────────────────┼─────────────────────────────────────┘   │
└────────────────────────┼─────────────────────────────────────────┘
                         │ Plan / Apply
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                              AWS                                  │
│                                                                   │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                      Packer                               │   │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐              │   │
│   │  │ Bastion  │  │  Nginx   │  │WordPress │              │   │
│   │  │   AMI    │  │   AMI    │  │   AMI    │              │   │
│   │  └──────────┘  └──────────┘  └──────────┘              │   │
│   └─────────────────────────────────────────────────────────┘   │
│                              │                                    │
│                              ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                 Launch Templates                         │   │
│   │            (Uses custom AMIs from Packer)                │   │
│   └─────────────────────────────────────────────────────────┘   │
│                              │                                    │
│                              ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │               Auto Scaling Groups                        │   │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐              │   │
│   │  │ Bastion  │  │  Nginx   │  │WordPress │              │   │
│   │  │   ASG    │  │   ASG    │  │   ASG    │              │   │
│   │  └──────────┘  └──────────┘  └──────────┘              │   │
│   └─────────────────────────────────────────────────────────┘   │
│                              │                                    │
│                              ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │         ┌──────────┐         ┌──────────┐              │   │
│   │         │ External │         │ Internal │              │   │
│   │         │   ALB    │◀───────▶│   ALB    │              │   │
│   │         └──────────┘         └──────────┘              │   │
│   └─────────────────────────────────────────────────────────┘   │
│                              │                                    │
│                              ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                      Ansible                              │   │
│   │  ┌───────────────────────────────────────────────────┐  │   │
│   │  │  Dynamic Inventory → Configuration → Deployment   │  │   │
│   │  └───────────────────────────────────────────────────┘  │   │
│   └─────────────────────────────────────────────────────────┘   │
│                              │                                    │
│                              ▼                                    │
│   ┌──────────────┐                              ┌──────────────┐ │
│   │     EFS      │                              │     RDS      │ │
│   │  (KMS encrypted)│                              │  (MySQL 5.7)  │ │
│   └──────────────┘                              └──────────────┘ │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## **📁 Repository Structure**

```
terraform-cloud/
├── AMI/                              # Packer configurations for custom AMIs
│   ├── linux/                        # Linux-specific configurations
│   │   └── ubuntu.pkr.hcl            # Ubuntu source AMI definition
│   ├── locals.pkr.hcl                 # Local variables for Packer
│   ├── packer-configs/                # Role-specific Packer templates
│   │   ├── bastion.pkr.hcl            # Bastion host AMI
│   │   ├── nginx.pkr.hcl              # Nginx reverse proxy AMI
│   │   └── wordpress.pkr.hcl          # WordPress application AMI
│   ├── plugins.pkr.hcl                 # Packer plugin declarations
│   ├── scripts/                        # Provisioning scripts
│   │   ├── base-setup.sh               # Base system setup
│   │   ├── cleanup.sh                   # AMI cleanup tasks
│   │   ├── install-nginx.sh             # Nginx installation
│   │   └── install-wordpress.sh         # WordPress installation
│   ├── variables.pkr.hcl                # Packer variables
│   └── windows/                          # Windows configurations (future)
│
├── ansible/                             # Ansible configuration management
│   ├── ansible.cfg                       # Ansible configuration
│   ├── group_vars/                        # Group variables
│   │   ├── all.yml                         # Global variables
│   │   └── webservers.yml                   # Web server variables
│   ├── inventories/                        # Inventory definitions
│   │   └── aws_ec2.yaml                     # Dynamic AWS inventory
│   ├── playbooks/                          # Ansible playbooks
│   │   ├── deploy-nginx.yml                  # Nginx deployment
│   │   ├── deploy-wordpress.yml               # WordPress deployment
│   │   ├── hardening.yml                      # Security hardening (Packer-time)
│   │   ├── post-deployment.yml                # Post-deployment verification
│   │   └── site.yml                           # Main playbook
│   ├── requirements.yml                      # External role dependencies
│   ├── roles/                                # Ansible roles
│   │   ├── common/                            # Common role (all servers)
│   │   │   ├── defaults/                        # Default variables
│   │   │   │   └── main.yml
│   │   │   ├── handlers/                        # Handlers
│   │   │   │   └── main.yml
│   │   │   └── tasks/                           # Tasks
│   │   │       └── main.yml
│   │   ├── nginx/                              # Nginx role
│   │   │   ├── defaults/                         # Default variables
│   │   │   │   └── main.yml
│   │   │   ├── handlers/                         # Handlers
│   │   │   │   └── main.yml
│   │   │   ├── tasks/                            # Tasks
│   │   │   │   └── main.yml
│   │   │   └── templates/                        # Templates
│   │   │       ├── nginx.conf.j2
│   │   │       └── site.conf.j2
│   │   └── wordpress/                          # WordPress role
│   │       ├── defaults/                         # Default variables
│   │       │   └── main.yml
│   │       ├── handlers/                         # Handlers
│   │       │   └── main.yml
│   │       ├── tasks/                            # Tasks
│   │       │   └── main.yml
│   │       └── templates/                        # Templates
│   │           ├── wordpress.conf.j2
│   │           └── wp-config.php.j2
│   └── templates/                             # Global templates
│       ├── fail2ban.local.j2
│       └── ntp.conf.j2
│
├── modules/                             # Terraform reusable modules
│   ├── alb/                              # Application Load Balancer module
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── autoscaling/                      # Auto Scaling Group module
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── compute/                          # Compute resources module
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── efs/                              # Elastic File System module
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── network/                          # VPC networking module
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── rds/                              # RDS database module
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── security/                         # Security groups module
│       ├── main.tf
│       ├── outpouts.tf
│       └── variables.tf
│
├── screenshots/                         # Verification screenshots
│   ├── Email_notification_sent.png
│   ├── configuring_Environment_variables_page.png
│   ├── configuring_vcs_only_dev_branch_auto_trigger.png
│   ├── create_new_workspace_dashboard.png
│   ├── destroying_resprces.png
│   ├── github_dev_prod_branches.png
│   ├── notification_created.png
│   ├── private_registry_dashboard.png
│   └── triggering_terraform_plan_ui.png
│
├── user-data/                           # EC2 user data scripts
│   ├── bastion.sh
│   ├── nginx.sh
│   ├── tooling.sh
│   └── wordpress.sh
│
├── backup/                              # Backup of original monolithic files
│   ├── alb.tf
│   ├── asg-bastion-nginx.tf
│   ├── asg-wordpress-tooling.tf
│   ├── efs.tf
│   ├── internet_gateway.tf
│   ├── natgateway.tf
│   ├── outputs.tf
│   ├── rds.tf
│   ├── roles.tf
│   ├── route_tables.tf
│   └── security.tf
│
├── backend.tf                           # Terraform Cloud backend configuration
├── main.tf                              # Root module calling child modules
├── providers.tf                         # Provider configuration
├── variables.tf                         # Root variables
├── terraform.tfvars                      # Variable values
├── outputs.tf                            # Root outputs
├── tfplan                                # Terraform plan file
├── terraform.tfstate                      # Terraform state file
└── terraform.tfstate.backup               # State backup
```

---

## **🚀 Implementation Steps**

### **Phase 1: Terraform Cloud Account and Workspace Setup**

#### **Step 1: Create Terraform Cloud Account**

1. Navigated to [app.terraform.io](https://app.terraform.io)
2. Created account using GitHub authentication
3. Verified email address

#### **Step 2: Create Organization**

- Selected "Start from scratch"
- Created organization: `brian-terraform-org`

#### **Step 3: Create GitHub Repository and Push Code**

```bash
# Created .gitignore for Terraform files
cat > .gitignore << EOF
**/.terraform/*
*.tfstate
*.tfstate.*
crash.log
*.tfvars
.terraformrc
EOF

# Initialized git and pushed code
git init
git add .
git commit -m "Initial commit with Terraform code"
git remote add origin https://github.com/brianmunyat/terraform-cloud.git
git push -u origin main
```

#### **Step 4: Create Workspace with VCS Integration**

| Step | Action                                         |
| ---- | ---------------------------------------------- |
| 1    | Clicked "New workspace" in Terraform Cloud     |
| 2    | Selected "Version control workflow"            |
| 3    | Connected GitHub account and authorized access |
| 4    | Selected `terraform-cloud` repository          |
| 5    | Configured workspace: `dev-infrastructure`     |

![Creating a new workspace](screenshots/create_new_workspace_dashboard.png)
_Figure 1: Creating a new workspace with version control workflow in Terraform Cloud_

#### **Step 5: Configure Variables**

Added environment variables for AWS authentication:

| Variable                | Value                | Sensitive |
| ----------------------- | -------------------- | --------- |
| `AWS_ACCESS_KEY_ID`     | AKIAXXXXXXXXXXXXXXXX | No        |
| `AWS_SECRET_ACCESS_KEY` | [hidden]             | Yes       |
| `AWS_DEFAULT_REGION`    | us-east-1            | No        |

![Environment variables configuration](screenshots/configuring_Environment_variables_page.png)
_Figure 2: Configuring AWS credentials as environment variables in Terraform Cloud_

---

### **Phase 2: Packer AMI Configuration**

Created custom AMIs using Packer with Ansible provisioners:

#### **AMI Components:**

| File                                   | Purpose                             |
| -------------------------------------- | ----------------------------------- |
| `AMI/plugins.pkr.hcl`                  | Declares required Packer plugins    |
| `AMI/variables.pkr.hcl`                | Defines Packer variables            |
| `AMI/locals.pkr.hcl`                   | Local variables and computed values |
| `AMI/linux/ubuntu.pkr.hcl`             | Ubuntu source AMI configuration     |
| `AMI/packer-configs/bastion.pkr.hcl`   | Bastion host AMI definition         |
| `AMI/packer-configs/nginx.pkr.hcl`     | Nginx reverse proxy AMI             |
| `AMI/packer-configs/wordpress.pkr.hcl` | WordPress application AMI           |
| `AMI/scripts/base-setup.sh`            | Base system setup script            |
| `AMI/scripts/install-nginx.sh`         | Nginx installation script           |
| `AMI/scripts/install-wordpress.sh`     | WordPress installation script       |
| `AMI/scripts/cleanup.sh`               | AMI cleanup script                  |

**Key Packer Configuration** (simplified):

```hcl
# AMI/packer-configs/bastion.pkr.hcl
build {
  sources = ["source.amazon-ebs.ubuntu-22-04"]

  provisioner "shell" {
    script = "${path.root}/scripts/base-setup.sh"
  }

  provisioner "ansible" {
    playbook_file = "../ansible/playbooks/hardening.yml"
  }
}
```

---

### **Phase 3: Ansible Configuration Management**

#### **Ansible Structure:**

| Component                                | Description                      |
| ---------------------------------------- | -------------------------------- |
| `ansible/ansible.cfg`                    | Main Ansible configuration       |
| `ansible/inventories/aws_ec2.yaml`       | Dynamic AWS inventory plugin     |
| `ansible/group_vars/all.yml`             | Global variables                 |
| `ansible/playbooks/hardening.yml`        | Security hardening (Packer-time) |
| `ansible/playbooks/deploy-nginx.yml`     | Nginx deployment                 |
| `ansible/playbooks/deploy-wordpress.yml` | WordPress deployment             |
| `ansible/roles/common/`                  | Common role for all servers      |
| `ansible/roles/nginx/`                   | Nginx-specific role              |
| `ansible/roles/wordpress/`               | WordPress-specific role          |
| `ansible/templates/`                     | Jinja2 templates                 |

**Dynamic Inventory Configuration**:

```yaml
# ansible/inventories/aws_ec2.yaml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  instance-state-name: running
  tag:Environment: production
keyed_groups:
  - key: tags.Role
    prefix: role
```

---

### **Phase 4: First Run and Automated Plans**

#### **Manual Plan and Apply**

1. Navigated to "Runs" tab in workspace
2. Clicked "Queue plan manually"
3. Reviewed plan output
4. Confirmed and applied

![Triggering Terraform plan](screenshots/triggering_terraform_plan_ui.png)
_Figure 3: Triggering a manual Terraform plan from the Terraform Cloud web console_

#### **Automated Plan Test**

After pushing a change to GitHub, Terraform Cloud automatically queued a new plan:

```bash
echo "# Test automated plan" >> README.md
git add .
git commit -m "test: trigger automated plan"
git push origin main
```

The plan ran automatically, but apply required manual approval.

---

### **Phase 5: Practice Task #1 - Multi-Environment Setup**

#### **Step 1: Create Git Branches**

```bash
git checkout -b dev
git push origin dev

git checkout -b test
git push origin test

git checkout -b prod
git push origin prod
```

![GitHub branches](screenshots/github_dev_prod_branches.png)
_Figure 4: GitHub branches created for dev, test, and prod environments_

#### **Step 2: Create Environment-Specific Workspaces**

| Workspace             | Branch | Auto-apply |
| --------------------- | ------ | ---------- |
| `dev-infrastructure`  | dev    | Enabled    |
| `test-infrastructure` | test   | Disabled   |
| `prod-infrastructure` | prod   | Disabled   |

#### **Step 3: Configure VCS Triggers for Dev Only**

Configured workspace settings to auto-trigger only on dev branch:

![VCS configuration for dev branch](screenshots/configuring_vcs_only_dev_branch_auto_trigger.png)
_Figure 5: Configuring VCS to auto-trigger only for dev branch_

---

### **Phase 6: Notifications Configuration**

#### **Email Notifications**

Created email notification for all run events:

| Setting     | Value             |
| ----------- | ----------------- |
| Name        | "Email Alerts"    |
| Destination | Email             |
| Recipients  | brian@example.com |
| Triggers    | All events        |

![Creating notification](screenshots/notification_created.png)
_Figure 6: Creating an email notification in Terraform Cloud_

![Email notification received](screenshots/Email_notification_sent.png)
_Figure 7: Email notification received for a Terraform Cloud run_

#### **Slack Notifications** (Optional)

Configured Slack webhook for team notifications.

---

### **Phase 7: Destroy Infrastructure**

Performed infrastructure destruction from Terraform Cloud web console:

1. Navigated to workspace Settings → Destruction and Deletion
2. Queued destroy plan
3. Reviewed resources to be destroyed
4. Confirmed destruction

![Destroying infrastructure](screenshots/destroying_resprces.png)
_Figure 8: Destroying infrastructure from Terraform Cloud console_

---

### **Phase 8: Practice Task #2 - Private Module Registry**

#### **Step 1: Create Simple Module**

Created a separate module repository with S3 bucket module.

#### **Step 2: Import to Private Registry**

1. Navigated to Registry → Modules
2. Clicked "Add module"
3. Selected GitHub repository
4. Published version v1.0.0

![Private module registry](screenshots/private_registry_dashboard.png)
_Figure 9: Private module registry dashboard with published module_

#### **Step 3: Test Module Deployment**

Created a test configuration using the private module and deployed successfully.

---

## **📊 Key Achievements**

### **1. Successful Terraform Cloud Migration**

- ✅ Remote state management with automatic versioning
- ✅ State locking with DynamoDB
- ✅ Team collaboration ready

### **2. VCS-Driven Workflow Implementation**

- ✅ GitHub integration with automatic plan triggers
- ✅ Manual approval gates for production
- ✅ Speculative plans on pull requests

### **3. Multi-Environment Configuration**

- ✅ Dev, test, and prod branches
- ✅ Auto-apply only for dev environment
- ✅ Isolated workspaces per environment

### **4. Comprehensive Notification System**

- ✅ Email notifications for all run events
- ✅ Slack integration for team alerts
- ✅ Real-time infrastructure change awareness

### **5. Private Module Registry**

- ✅ Reusable internal modules
- ✅ Version-controlled infrastructure components
- ✅ Standardized deployment patterns

### **6. Packer + Ansible Integration**

- ✅ Custom AMI building pipeline
- ✅ Security hardening at image level
- ✅ Configuration management with Ansible roles

---

## **🛠️ Technologies Used**

| Technology      | Purpose                     | Version |
| --------------- | --------------------------- | ------- |
| Terraform       | Infrastructure provisioning | v1.6.0+ |
| Terraform Cloud | Remote state & operations   | SaaS    |
| Packer          | Custom AMI building         | v1.9.0+ |
| Ansible         | Configuration management    | v2.15+  |
| AWS             | Cloud provider              | -       |
| GitHub          | Version control             | -       |
| Slack           | Notifications               | -       |

---

## **📸 Screenshots Gallery**

| Screenshot                                                                         | Description                                                        |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| ![Workspace Creation](screenshots/create_new_workspace_dashboard.png)              | **Figure 1**: Creating a new workspace in Terraform Cloud          |
| ![Environment Variables](screenshots/configuring_Environment_variables_page.png)   | **Figure 2**: Configuring AWS credentials as environment variables |
| ![Manual Plan](screenshots/triggering_terraform_plan_ui.png)                       | **Figure 3**: Triggering a manual Terraform plan from web UI       |
| ![VCS Configuration](screenshots/configuring_vcs_only_dev_branch_auto_trigger.png) | **Figure 4**: Configuring VCS auto-trigger for dev branch only     |
| ![GitHub Branches](screenshots/github_dev_prod_branches.png)                       | **Figure 5**: GitHub branches for dev, test, and prod environments |
| ![Notification Creation](screenshots/notification_created.png)                     | **Figure 6**: Creating email notification in Terraform Cloud       |
| ![Email Notification](screenshots/Email_notification_sent.png)                     | **Figure 7**: Email notification received for Terraform run        |
| ![Destroy Resources](screenshots/destroying_resprces.png)                          | **Figure 8**: Destroying infrastructure from Terraform Cloud       |
| ![Private Registry](screenshots/private_registry_dashboard.png)                    | **Figure 9**: Private module registry dashboard                    |

---

## **🔧 Troubleshooting Guide**

### **Common Issues and Solutions**

| Issue                          | Solution                            |
| ------------------------------ | ----------------------------------- |
| Backend configuration changed  | Run `terraform init -migrate-state` |
| Resource already exists        | Import resource or remove manually  |
| VCS connection failed          | Check GitHub App permissions        |
| Plan fails with no credentials | Verify AWS environment variables    |
| State lock errors              | Wait for completion or force unlock |

---

## **🎓 Learning Outcomes**

### **Terraform Cloud Concepts**

- Remote state management benefits
- VCS-driven workflow implementation
- Workspace isolation for environments
- Notification configuration

### **Infrastructure as Code Best Practices**

- Modular code structure
- Environment separation
- Immutable infrastructure with Packer
- Configuration management with Ansible

### **Team Collaboration Features**

- State locking prevents conflicts
- Run history provides audit trail
- Notifications enable real-time awareness
- Private modules promote reuse

---

## **📝 Conclusion**

This project successfully demonstrates the migration of a complete Terraform infrastructure to **Terraform Cloud**, transforming a local development workflow into a professional, team-ready platform. Key achievements include:

✅ **Centralized State Management** - No more local state files or conflicts  
✅ **Automated Workflows** - Plans triggered on every Git push  
✅ **Environment Isolation** - Separate workspaces for dev/test/prod  
✅ **Operational Visibility** - Email and Slack notifications  
✅ **Reusable Components** - Private module registry for internal standards  
✅ **Immutable Infrastructure** - Packer-built AMIs with Ansible configuration

The infrastructure is now production-ready with proper governance, collaboration features, and operational excellence. This setup mirrors how infrastructure is managed in enterprise environments, providing a solid foundation for future projects.

---

## **📚 References**

- [Terraform Cloud Documentation](https://www.terraform.io/docs/cloud)
- [Packer Documentation](https://www.packer.io/docs)
- [Ansible Documentation](https://docs.ansible.com)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
