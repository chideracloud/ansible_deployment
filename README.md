# Ansible Deployment on AWS with Terraform

This project automates the provisioning and configuration of a highly available web server infrastructure on AWS using **Terraform** for infrastructure setup and **Ansible** for server configuration management.

# Project Objectives

- Provision a VPC with public subnets across multiple Availability Zones.
- Deploy 3 EC2 instances in a load-balanced setup using an Application Load Balancer (ALB).
- Use Route 53 to map a custom domain to the ALB.
- Automatically install and configure Apache HTTP server on all instances using Ansible.
- Export instance IPs dynamically for Ansible inventory.

---

# Infrastructure Overview

| Tool      | Purpose                                 |
|-----------|------------------------------------------|
| Terraform | Provision AWS resources                  |
| Ansible   | Configure EC2 instances                  |
| AWS       | Cloud provider for infrastructure        |
| Route 53  | DNS management with a custom domain name |
| ALB       | Load balancing across EC2 instances      |

---

# Project Structure

