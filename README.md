# Hardened EKS Cluster

A production-ready Amazon EKS cluster built with Terraform, focusing on security and high availability.

## Overview

This project provisions a Kubernetes cluster on AWS using EKS with security best practices. The infrastructure is spread across multiple availability zones and uses private subnets to isolate workloads from direct internet access.

## Architecture

The cluster is deployed in the us-west-2 region across two availability zones. Worker nodes run in private subnets and can only reach the internet through a NAT gateway. Public subnets are reserved for load balancers that need to accept external traffic.

The VPC uses a 10.0.0.0/16 CIDR block with the following subnets:

* Public subnets: 10.0.1.0/24 (zone a), 10.0.2.0/24 (zone b)
* Private subnets: 10.0.10.0/24 (zone a), 10.0.20.0/24 (zone b)

## Security Features

The cluster implements several hardening measures:

**Network Isolation**: Worker nodes are placed in private subnets with no direct internet access. Outbound traffic is routed through a NAT gateway, and inbound traffic can only reach the nodes through load balancers or the EKS API server.

**IAM Integration**: The cluster uses IAM roles for service accounts (IRSA) and the modern EKS Access Entry API for managing cluster access. This replaces the older ConfigMap-based authentication system.

**Multi-AZ Deployment**: Resources are distributed across two availability zones to provide high availability and fault tolerance.

## Prerequisites

You'll need the following installed:

* Terraform (version 1.0 or later)
* AWS CLI configured with appropriate credentials
* kubectl for interacting with the cluster

Your AWS credentials should have permissions to create VPCs, subnets, EKS clusters, IAM roles, and related resources.

## Deployment

Initialize Terraform and download the required providers:

```bash
cd infrastructure
terraform init
```

Review the infrastructure that will be created:

```bash
terraform plan
```

Apply the configuration to create the cluster:

```bash
terraform apply
```

The deployment takes about 10-15 minutes. Once complete, configure kubectl to access the cluster:

```bash
aws eks update-kubeconfig --region us-west-2 --name hardened-eks-cluster
```

## Project Structure

```
infrastructure/
  eks.tf           # EKS cluster and node group configuration
  vpc.tf           # VPC, subnets, and networking resources
  iam.tf           # IAM roles and policies
  provider.tf      # Terraform and AWS provider configuration
  variables.tf     # Input variables (currently empty)
```

## Cost Considerations

Running this infrastructure will incur AWS costs. The main components are:

* EKS cluster: $0.10/hour
* EC2 instances: 2x t3.medium instances (pricing varies by region)
* NAT Gateway: $0.045/hour plus data transfer costs
* Elastic IP: $0.005/hour when not attached

Remember to destroy the infrastructure when you're done testing:

```bash
terraform destroy
```


## Future Improvements

Some things I'd like to add:

* CloudWatch logging for cluster audit logs
* Pod security policies or Pod Security Standards
* Network policies for restricting pod-to-pod communication
* Automated backup solution for cluster state
* CI/CD pipeline for deploying applications to the cluster

