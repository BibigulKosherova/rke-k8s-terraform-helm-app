```
# RKE Kubernetes Cluster Automation with Terraform, Ansible & Helm 

This project automates the full provisioning of a **Kubernetes cluster** on AWS using **Rancher Kubernetes Engine (RKE)** and the deployment of a **3-tier application** (web, api, MySQL). It follows a modular and infrastructure-as-code approach using **Terraform**, **Ansible**, **Docker**, **Helm**, and **Bash scripting** to streamline everything from virtual machine creation to application deployment.

---

## 🔧 Architecture Overview

### 1. AWS Workstation VM (Provisioning Host)
A dedicated EC2 instance is used as a **bastion** or **jump host**. It is the single point of control for the entire automation process.

- The script includes a function `prepare_bastion` that:
  - Installs **Terraform**, **Ansible**, **RKE**, **Docker**, **Helm**, and **kubectl**
  - Prepares the environment for executing all provisioning and deployment tasks

> All infrastructure and cluster actions are triggered from this machine.

---

### 2. Terraform Stage I – VM Provisioning (`terraform-vms/`)
- Provisions 3 EC2 virtual machines inside AWS's default VPC
- Sets up SSH access and security groups
- These VMs will be used as worker nodes in the Kubernetes cluster

---

### 3.  Ansible – Docker Installation (`ansible/`)
- Ansible installs Docker on each EC2 instance
- Ensures all nodes are Docker-ready for RKE to build the cluster

---

### 4. Terraform Stage II – RKE Cluster Setup (`terraform-rke/`)
- Terraform uses the **RKE provider** to bootstrap the Kubernetes cluster
- Includes cluster config and generates a `kube_config` file
- The cluster includes all 3 VMs as worker nodes

---

### 5. Terraform Stage III – Helm Deployments (`k8s-deployments/`)
- Uses Terraform to deploy **three Helm charts**: `web`, `api`, and `mysql`
- Charts are located in `helm/` and define:
  - Docker images
  - Deployments with `ConfigMaps`, `Secrets`, health probes
  - Resource limits and rolling update strategy
  - MySQL is deployed as a `StatefulSet` 

---

### 6. Ingress & Service Exposure

- Instead of exposing services via `NodePort`, the setup uses **NGINX Ingress Controller**.
- Ingress is installed automatically by the script with `helm install ingress-nginx`.
- Services are of type `ClusterIP` and accessed **externally** through the ingress controller via **NodePort 30080** (HTTP).
- Paths:
  - `/` routes to the **web** frontend
  - `/api` routes to the **backend API**


---

## Application Details

| Component | Type        | Description                             |
|-----------|-------------|-----------------------------------------|
| **Web**   | Deployment  | Frontend Node.js application            |
| **API**   | Deployment  | Backend Node.js application             |
| **MySQL** | StatefulSet | Relational database with persistent volume |

- **Dockerized** apps with separate Dockerfiles
- Runtime variables managed via `ConfigMap` and `Secret`
- **Readiness & Liveness Probes** configured (`/health`)
- **Resource Requests & Limits** defined


---

## Deployment Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/BibigulKosherova/rke-k8s-terraform-helm-app.git
   cd rke-k8s-terraform-helm-app
   ```

2. **Make the script executable and run it**
   ```bash
   chmod +x script.sh
   ./script.sh
   ```

3. The script performs:
   - `prepare_bastion`: installs necessary tools on the workstation
   - `terraform apply` in `terraform-vms/`: provisions EC2 instances
   - `ansible-playbook`: installs Docker
   - `terraform apply` in `terraform-rke/`: builds the cluster
   - `terraform apply` in `k8s-deployments/`: deploys Helm charts

4. **Access the app**
   - Find EC2 public IP
   - Get NodePort via:
     ```bash
     kubectl get svc -n default
     ```
   - Visit:
     ```
     http://<node-ip>:<nodePort>
     ```

---

## 🔗 References

- [Setup a basic Kubernetes cluster using RKE](https://itnext.io/setup-a-basic-kubernetes-cluster-with-ease-using-rke-a5f3cc44f26f)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Terraform RKE Provider](https://registry.terraform.io/providers/rancher/rke/latest)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Probes Best Practices](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
```