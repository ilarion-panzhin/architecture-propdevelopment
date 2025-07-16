# Привязка admin-user к admin-role (ClusterRoleBinding)
kubectl apply -f bindings/admin-binding.yaml

# Привязка dev-user к developer-role (RoleBinding)
kubectl apply -f bindings/developer-binding.yaml
