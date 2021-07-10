resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_in_days
  tags              = merge(
    var.tags,
    {
      "Name": "${var.cluster_name}-cloudwatch-log-group"
    },
  )
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  description        = "EKS cluster IAM Role"

  tags               = merge(
    var.tags,
    {
      "Name": "${var.cluster_name}-cluster-role"
    },
  )

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" # Amazon owner
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy" # Amazon owner
  role       = aws_iam_role.cluster.name
}

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-security-group"
  description = "${var.cluster_name} eks security group"
  
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    { 
      "Name": "${var.cluster_name} cluster security group"
    },
    { 
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
  )

  # I decide to do this rule because if another aws resource needs to administrate the cluster, ex any bastion machine, just attach this security group to itself.
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "all"
    self      = true
  }

  egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "this" {
  # https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
  description              = "Allow pods to communicate with the cluster API Server"
  type                     = "ingress"

  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node_group.id
}

resource "aws_eks_cluster" "cluster" {
  name                      = var.cluster_name
  version                   = var.cluster_version
  role_arn                  = aws_iam_role.cluster.arn
  enabled_cluster_log_types = var.enable_cluster_logs == null ? [] : var.enable_cluster_logs

  vpc_config {
    security_group_ids      = [
      aws_security_group.cluster.id,
      aws_security_group.node_group.id
    ]
    subnet_ids              = var.private_subnets_id
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
  }

  tags                      = merge(
    var.tags,
    {
      "Name": var.cluster_name
    },
  )
}

locals {
  kubeconfig          = templatefile("${path.module}/templates/kubeconfig.tpl", {
  cluster_endpoint    = aws_eks_cluster.cluster.endpoint
  cluster_auth_base64 = aws_eks_cluster.cluster.certificate_authority[0].data
  aws_profile_name    = var.aws_profile_name
  cluster_name        = var.cluster_name
  aws_region          = var.aws_region
  })
}

resource "local_file" "kubeconfig" {
  count                = 1
  content              = local.kubeconfig
  filename             = "/tmp/kube.conf"
  file_permission      = "0644"
  directory_permission = "0755"
}

resource "null_resource" "eks_cluster_auto_scaler" {
  provisioner "local-exec" {
    command       = <<EOT
      envsubst < ${path.module}/templates/cluster-autoscaler-autodiscover.yaml | kubectl apply --kubeconfig /tmp/kube.conf -f -
    EOT
  
    environment   = {
      CLUSTERNAME = var.cluster_name
    }
  }

  triggers        = {
    sha1          = filesha1("${path.module}/templates/cluster-autoscaler-autodiscover.yaml")
  }

  depends_on      = [
    aws_eks_node_group.node
  ]
}

resource "null_resource" "aws_auth" {
  count                    = length(var.map_users) > 0 || length(var.map_roles) > 0 ? 1 : 0

  provisioner "local-exec" {
    command                = <<EOT
      kubectl apply --kubeconfig /tmp/kube.conf -f - <<EOF${templatefile("${path.module}/templates/aws-auth.yaml.tpl", {
        EC2PrivateDNSName  = "{{EC2PrivateDNSName}}"
        nodegroups_iam_arn = aws_iam_role.node_group.arn
        map_roles          = var.map_roles
        map_users          = var.map_users
      })}EOF
    EOT
  }

  depends_on               = [
    aws_eks_node_group.node
  ]
}