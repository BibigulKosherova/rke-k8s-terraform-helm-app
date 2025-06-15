#!/bin/bash

set -e

echo "[INFO] Uninstalling NGINX Ingress Controller..."
helm uninstall ingress -n default || true

echo "[INFO] Destroying Helm charts from k8s-deployments..."
cd k8s-deployments || exit 1
terraform destroy -auto-approve
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
cd ..

echo "[INFO] Destroying RKE cluster..."
cd terraform-rke || exit 1
terraform destroy -auto-approve
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
cd ..

echo "[INFO] Destroying EC2 instances..."
cd terraform-vms || exit 1
terraform destroy -auto-approve
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
cd ..

echo "[INFO] Reset complete."
