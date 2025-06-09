#!/bin/bash

#install ansible, terraform
function prepare_bastion() {
    sudo apt update

    # install ansible
    sudo apt install ansible -y

    # install terraform
    if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]
    then 
    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    fi
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform -y

    # install rke
    wget https://github.com/rancher/rke/releases/download/v1.8.3/rke_linux-amd64
    mv rke_linux-amd64 rke
    chmod +x rke
    sudo mv rke /usr/local/bin

    # install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin

    # install docker
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    VERSION_STRING=5:24.0.9-1~ubuntu.22.04~jammy
    sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin -y 
    sudo usermod -aG docker ubuntu


    # install jq (JSON processor)
    sudo apt update
    sudo apt install -y jq

    #install helm
    mkdir -p helm
    cd helm
    wget https://get.helm.sh/helm-v3.18.2-linux-amd64.tar.gz
    tar zxf helm-*
    sudo mv linux-amd64/helm /usr/local/bin/helm
    helm version
    cd ..

}


function create_instance() {
    cd terraform-vms
    terraform init
    terraform apply -auto-approve
    cd ..
}

function update_ip() {
    echo "[INFO] Getting public IPs from Terraform output..."
    ips=($(terraform -chdir=terraform-vms output -json public_ips | jq -r '.[]'))

    {
        echo "[rke_nodes]"
        for ip in "${ips[@]}"; do
            echo "$ip"
        done
    } > ansible/hosts
}



function ansible() {
    cd ansible
    ansible-playbook main.yml
    cd ..
}

function create_rke_cluster() {
    cd terraform-rke
    terraform init
    terraform apply -auto-approve
    mkdir -p ~/.kube
    terraform output -raw kube_config_yaml > ~/.kube/config
    cd ..
}


function create_sc() {
	kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml
	kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
}

function install_metrics_server() {
    echo "[INFO] Installing metrics-server with --kubelet-insecure-tls..."
    curl -Lo /tmp/metrics-server.yaml https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    sed -i '/args:/a \        - --kubelet-insecure-tls' /tmp/metrics-server.yaml
    kubectl apply -f /tmp/metrics-server.yaml

    echo "[INFO] Waiting for metrics-server to be ready..."
    kubectl wait --namespace kube-system \
        --for=condition=Available \
        deployment/metrics-server \
        --timeout=60s || true

    sleep 5
    echo "[INFO] Testing metrics availability..."
    kubectl top nodes 2>/dev/null || echo "Metrics not ready yet."
    kubectl top pods -A 2>/dev/null || echo "Metrics not ready yet."
}

prepare_bastion
create_instance
update_ip
echo "Waiting 20 seconds"
sleep 20
ansible

echo "[INFO] Waiting for Docker to become ready on all nodes..."

for ip in "${ips[@]}"; do
  echo "Checking Docker on $ip..."
  until ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa rke@$ip "docker info" &>/dev/null; do
    echo "Docker not ready on $ip, waiting 5s..."
    sleep 5
  done
  echo "Docker is ready on $ip"
done

create_rke_cluster
create_sc
install_metrics_server