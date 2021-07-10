# Changelog

## Unreleased

## v4.0 - 2021-07-10

- Restruturação do modulo e do projeto
- Remoção da criação da VPC
- Adição do Cloudwatch Log Group para o cluster
- Adição de outputs
- Adição do provider
- Adição da versão requerida do terraform para utilizar o projeto
- Remoção de exemplos de utilização com VPC
- Mudança no security group do cluster e do node group

## v3.1.1 - 2021-05-24

- Adição do arquivo kubeconfig via output

## v3.0.1 - 2021-05-21

- Remoção da criação do bastion(Achei desnecessário a criação de um bastion)

- Fix nos tageamentos das subnets para o alb

- Agora é opcional usar o alb como Ingress Controller

## v2.0.1 - 2021-01-21

- Fix no configmap `aws-auth`

## v2.0.0 - 2021-01-04

- Adicionado suporte a usuários e Roles do IAM a administrarem o cluster

- Adicionado exemplos de utilização do modulo

## v1.0.0 - 2020-12-19

- Versão Inicial
