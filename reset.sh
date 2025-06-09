#!/bin/bash

set -e

cd terraform-rke || exit 1
terraform destroy -auto-approve
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
cd ..
cd terraform-vms || exit 1
terraform destroy -auto-approve
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
cd ..

