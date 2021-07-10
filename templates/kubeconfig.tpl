apiVersion: v1
preferences: {}
kind: Config

clusters:
- cluster:
    server: ${cluster_endpoint}
    certificate-authority-data: ${cluster_auth_base64}
  name: ${cluster_name}

contexts:
- context:
    cluster: ${cluster_name}
    user: ${cluster_name}
  name: ${cluster_name}

current-context: ${cluster_name}

users:
- name: ${cluster_name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      args:
      - --region
      - ${aws_region}
      - eks
      - get-token
      - --cluster-name
      - ${cluster_name}
      command: aws
      env:
  %{~ for k, v in aws_profile_name ~}
      - name: ${k}
        value: ${v}
  %{~ endfor ~}
