module "eks" {
  source                          = "github.com/danilo-lopes/eks"
  
  aws_profile_name                = { AWS_PROFILE = "foo" }

  aws_region                      = "us-east-1"

  vpc_id                          = "vpc-0ca4f458ad44a8d41"
  private_subnets_id              = ["subnet-01edb028041026cb6", "subnet-0431e84bf5fdc8a4e"]

  cluster_name                    = "foo"
  cluster_version                 = "1.20"

  enable_cluster_logs             = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  node_group_scaling_settings     = {
    desired_size                  = 1
    max_size                      = 5
    min_size                      = 1
  }

  map_users                       = [{
    userarn                       = "arn:aws:iam::12345678:user/foo"
    username                      = "bar"
    groups                        = ["system:masters"]
  }]

  map_roles                       = [{
    rolearn                       = "arn:aws:iam::12345678:role/foo"
    username                      = "foo"
    groups                        = ["system:masters"]
  }]

  node_group_shape                = "t3.large"
  
  tags                            = {
    team                          = "foo"
    environment                   = "hml"
    owner                         = "bar"
  }
}
