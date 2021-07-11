## Elastic Kubernetes Service

Modulo terraform para criar o serviço de Kubernetes gerenciado pelo EKS.

## Requisitos

| Nome | Version |
|------|---------|
| terraform | >= 0.14.0 |
| kubectl | >= 1.11.1 |
| aws-cli-v2 | >= 2.1.1 |

## Arquitetura

![img](cloud_diagram.png)

## Serviços Instalados no deploy do EKS

| Nome | Version |
|------|---------|
| autoscaler | 1.17.3 |
| alb ingress controller | 1.1.9 |

## Suposições

* Você deseja criar um cluster EKS e um AutoScaling Group para os Node Groups.

* Você quer utilizar como Load Balancer e Ingress Controller o [ALB](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)
 da AWS.

## Importante

Sempre verifique a [versão](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html) desejada do EKS 
no site da AWS.

Informe em `aws_profile_name` o profile AWS que provisionará o ambiente.

Opcional: caso queira acessar algum worker node é necessário criar manualmente a sua `Key Pair` e informa-la na variável
corespondente. Não foi criado a funcionalidade de criação automatica com o terraform por questões de [recomendação](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) da hashicorp e segurança.

## Documentações

* [Security Group Considerations](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html)

* [Auto-Scaling](https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html)

* [IAM](https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/iam-permissions.md)

## Inputs

| Nome | Descrição | Tipo | Default | Requerido |
|------|-----------|------|---------|-----------|
| aws_region| Região da AWS | string | null | Sim |
| tags | Tags adicionais | map(string) | {} | Não |
| vpc_id | ID da VPC que o EKS sera provisionado | string | null | Sim |
| private_subnets_id | IDs das subnets privadas que os worker nodes seram provisionados | list(string) | null | Sim |
| cluster_name | Nome dado ao cluster | string | null | Sim |
| cluster_version | Versão do EKS | string | null | Sim |
| enable_cluster_logs | Possibilita habilitar os logs de recursos especificos do cluster. Os logs são armazenados no cloudwatch log group| list(string) | null | Não |
| cluster_log_retention_in_days | Os dias de retenção dos logs do cluster no cloudwatch log group | number | 90 | Não |
| cluster_endpoint_public_access | Possibilitar o acesso via internet a API do EKS | bool | true | Não |
| cluster_endpoint_private_access | Possibilitar o acesso interno (Rede da AWS) a API do EKS | bool | true | Não |
| node_group_scaling_settings | Configurações de quantidade de worker nodes. Minimo, maximo e desejo atual. | map | null | Sim |
| node_group_shape | Tamanho dos worker nodes | string | null | Sim |
| aws_profile_name | Profile AWS que provisionara o ambiente | msp(string) | null | Sim |
| node_group_ssh_key_name | Chave SSH que administrará os worker nodes | string | null | Não |
| deploy_alb_controller | Escolher entre provisionar ou não o ALB Ingress Controller | bool | False | Não |
| map_users | Usuario do IAM que poderam administrar o cluster | list(object({})) | [] | Não |
| map_roles | Role do IAM que podera administrar o cluster | list(object({})) | [] | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
|cluster_id| Nome do cluster |
|cluster_arn| Amazon Resource Name do cluster |
|cluster_certificate_authority_data| Certificado de autorização de administração do cluster |
|cluster_endpoint| Endereço da API do EKS do cluster |
|cluster_version| versão provisionada do EKS |
|cluster_security_group_id| Security Group ID principal do cluster |
|cluster_iam_role_name| IAM role do cluster |
|cluster_iam_role_arn| Amazon Resource Name da role do cluster |
|cloudwatch_log_group_name| O nome do cloudwatch log group criado para os logs do componentes mais criticos do cluster |
|cloudwatch_log_group_arn| Amazon Resource Name do cloudwatch log group do cluster |
|kubeconfig| Arquivo kubeconfig para gerenciar o cluster |

## Veja

Na pasta examples possue exemplos de utilização do modulo.

### Em desenvolvimento
