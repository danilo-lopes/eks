
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - "rolearn": "${nodegroups_iam_arn}"
      "username": "system:node:{{EC2PrivateDNSName}}"
      "groups":
      - "system:bootstrappers"
      - "system:nodes"
    ${length(map_roles) >= 1 ? indent(4, yamlencode(map_roles)) : ""}
  mapUsers: |
    ${length(map_users) >= 1 ? indent(4, yamlencode(map_users)) : ""}
