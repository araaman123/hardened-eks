# 1. The EKS Cluster (The Brain)
resource "aws_eks_cluster" "main" {
  name     = "hardened-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.31" # Use a modern, stable version

  vpc_config {
    subnet_ids = [
      aws_subnet.public_zone_a.id,
      aws_subnet.private_zone_a.id,
      aws_subnet.public_zone_b.id,
      aws_subnet.private_zone_b.id
    ]
    # Hardening: In a production app, we would set this to 'false' 
    # to hide the API from the public internet entirely.
    endpoint_public_access = true 
  }

  access_config {
    authentication_mode = "API"
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

# 2. The EKS Node Group (The Muscle)
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  
  # We put the actual servers in the PRIVATE subnet for security
  subnet_ids      = [
    aws_subnet.private_zone_a.id,
    aws_subnet.private_zone_b.id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"] # t3.medium is the minimum recommended for EKS

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_policy,
  ]
}


resource "aws_eks_access_entry" "cloud_lab_admin" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = "arn:aws:iam::652662389483:user/cloud-lab-admin"
  type              = "STANDARD"
}


resource "aws_eks_access_policy_association" "cloud_lab_admin_policy" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.cloud_lab_admin.principal_arn

  access_scope {
    type = "cluster"
  }
}