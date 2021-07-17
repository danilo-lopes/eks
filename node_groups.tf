resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node_group.arn

  subnet_ids      = var.private_subnets_id

  tags            = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}"     = "owned"
      "k8s.io/cluster-autoscaler/enabled"             = true
      "k8s.io/cluster-autoscaler/${var.cluster_name}"	= "owned"
      "eks:cluster-name"                              = var.cluster_name
    },
  )

  scaling_config {
    desired_size  = lookup(var.node_group_scaling_settings, "desired_size", null)
    max_size      = lookup(var.node_group_scaling_settings, "max_size", null)
    min_size      = lookup(var.node_group_scaling_settings, "min_size", null)
  }

  dynamic remote_access {
    for_each      = var.node_group_ssh_key_name == null ? [] : [var.node_group_ssh_key_name]
    content {
      ec2_ssh_key = var.node_group_ssh_key_name
    }
  }

  instance_types  = [var.node_group_shape]

  depends_on      = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node-group-policy-autoscaler-policy-attachment
  ]
}

resource "aws_security_group" "node_group" {
    name        = "${var.cluster_name}-node-group-security-group"
    description = "${var.cluster_name} EKS Worker Nodes Security Group"

    vpc_id = var.vpc_id

    tags = merge(
      var.tags,
      { 
        "Name": "${var.cluster_name} node group security group"
      },
      { 
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      },
    )
}

resource "aws_security_group_rule" "workers_egress_internet" {
  description       = "Allow nodes all egress to the Internet."
  protocol          = "-1"
  security_group_id = aws_security_group.node_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "workers_ingress_self" {
  description              = "Allow node to communicate with each other."
  protocol                 = "-1"
  security_group_id        = aws_security_group.node_group.id
  source_security_group_id = aws_security_group.node_group.id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "workers_ingress_cluster" {
  description              = "Allow workers pods to receive communication from the cluster control plane."
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node_group.id
  source_security_group_id = aws_security_group.cluster.id
  from_port                = 1025
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "workers_ingress_cluster_kubelet" {
  description              = "Allow workers Kubelets to receive communication from the cluster control plane."
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node_group.id
  source_security_group_id = aws_security_group.cluster.id
  from_port                = 10250
  to_port                  = 10250
  type                     = "ingress"
}

resource "aws_security_group_rule" "workers_ingress_cluster_https" {
  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane."
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node_group.id
  source_security_group_id = aws_security_group.cluster.id
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "workers_ingress_cluster_primary" {
  description              = "Allow pods running on workers to receive communication from cluster primary security group (e.g. Fargate pods)."
  protocol                 = "all"
  security_group_id        = aws_security_group.node_group.id
  source_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_primary_ingress_workers" {
  description              = "Allow pods running on workers to send communication to cluster primary security group (e.g. Fargate pods)."
  protocol                 = "all"
  security_group_id        = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.node_group.id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_iam_role" "node_group" {
  name               = "${var.cluster_name}-node-group-role"
  description        = "This policy allows Amazon EKS node group to connect to Amazon EKS Clusters"

  tags               = merge(
    var.tags,
    {
      "Name": "${var.cluster_name}-node-group-role"
    },
  )

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "amazon_eks_node_group_autoscaler_policy" {
  name        = "${var.cluster_name}-node-group-autoscaler-policy"
  path        = "/"
  description = "${var.cluster_name} IAM Policy for EKS Node groups allowing to AutoScaling"

  tags = merge(
    var.tags,
    { 
      "Name": "${var.cluster_name} node group autoscaler policy"
    },
  )

  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" # Managed by Amazon
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy" # Managed by Amazon
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" # Managed by Amazon
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node-group-policy-autoscaler-policy-attachment" {
  policy_arn = aws_iam_policy.amazon_eks_node_group_autoscaler_policy.arn
  role       = aws_iam_role.node_group.name
}