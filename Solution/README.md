# Restauranty — Deployment Guide

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) — logged in via `az login`
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) >= 3

---

## Step 1 — Provision AKS with Terraform

```bash
cd terraform

terraform init
terraform plan
terraform apply
```

Connect kubectl to the new cluster (command is printed in terraform output):

```bash
az aks get-credentials --resource-group restauranty-rg --name restauranty-aks

# Verify
kubectl get nodes   # should show 2 nodes in Ready state
```

---

## Step 2 — Install NGINX Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

Get the public IP (this is your app's address):

```bash
kubectl get service ingress-nginx-controller -n ingress-nginx --watch
# Wait until EXTERNAL-IP is assigned — copy it
```

---

## Step 3 — Create the Namespace

```bash
kubectl apply -f k8s/namespace.yaml
```

---

## Step 4 — Inject Secrets

Do **not** edit `secrets.yaml` with real values. Use kubectl directly:

```bash
kubectl create secret generic restauranty-secrets \
  --namespace restauranty \
  --from-literal=SECRET="MySecret1!" \
  --from-literal=MONGODB_URI="mongodb://mongo-service:27017/restauranty" \
  --from-literal=CLOUD_NAME="dv4tqueh7" \
  --from-literal=CLOUD_API_KEY="639741712452721" \
  --from-literal=CLOUD_API_SECRET="your_actual_cloudinary_secret"
```

---

## Step 5 — Deploy All Workloads

Images are pulled directly from Docker Hub — no registry login needed.

```bash
# Deploy in dependency order
kubectl apply -f k8s/mongo/
kubectl apply -f k8s/auth/
kubectl apply -f k8s/discounts/
kubectl apply -f k8s/items/
kubectl apply -f k8s/client/
kubectl apply -f k8s/ingress.yaml
```

Verify everything is running:

```bash
kubectl get pods -n restauranty
kubectl get ingress -n restauranty
```

---

## Step 6 — Install Monitoring (Prometheus + Grafana)

```bash
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/values.yaml
```

Access Grafana locally:

```bash
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
# Open http://localhost:3000
# Login: admin / ChangeMe!
```

---

## Updating a Service

After pushing a new image to Docker Hub:

```bash
kubectl rollout restart deployment/auth -n restauranty
# Kubernetes does a zero-downtime rolling update automatically
```

## Useful Commands

```bash
# Logs for a service
kubectl logs -l app=auth -n restauranty --tail=100

# Debug a pod
kubectl describe pod -l app=items -n restauranty

# Check ingress routing
kubectl describe ingress restauranty-ingress -n restauranty

# Check all resources in namespace
kubectl get all -n restauranty
```
