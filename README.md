# Restauranty

A restaurant management platform built with a **microservices architecture**: 3 Node.js/Express backends + a React frontend, unified behind path-based routing (HAProxy locally, NGINX Ingress in production).

## Architecture

```
                         ┌────────────────────────┐
                         │   HAProxy / Ingress    │
    Browser ───────────► │       (port 80)        │
                         └───────────┬────────────┘
                                     │
            ┌────────────────────────┼─────────────────────────┐
            │                        │                         │
       /api/auth/*             /api/items/*             /api/discounts/*
            │                        │                         │
   ┌────────▼────────┐     ┌─────────▼─────────┐    ┌─────────▼──────────┐
   │  Auth Service   │     │  Items Service    │    │ Discounts Service  │
   │   (port 3001)   │     │   (port 3003)     │    │   (port 3002)      │
   └────────┬────────┘     └─────────┬─────────┘    └──────────┬─────────┘
            │                        │                         │
            └────────────────────────┼─────────────────────────┘
                                     │
                              ┌──────▼──────┐
                              │   MongoDB   │
                              │ (port 27017)│
                              └─────────────┘
```

## Microservices

| Service       | Port | Path               | Responsibilities                       |
| ------------- | ---- | ------------------ | -------------------------------------- |
| **Auth**      | 3001 | `/api/auth/*`      | User signup, login, JWT authentication |
| **Discounts** | 3002 | `/api/discounts/*` | Coupon and campaign management         |
| **Items**     | 3003 | `/api/items/*`     | Menu items, dietary categories, orders |
| **Frontend**  | 3000 | `/`                | React SPA (admin dashboard)            |

---

## Local Development

### 1. Clone the repository

```bash
git clone https://github.com/professordiogodev/devops.restauranty
cd devops.restauranty
```

### 2. Set up environment variables

Create a `.env` file in the root with:

```env
SECRET=MySecret1!
MONGODB_URI=mongodb://mongo:27017/restauranty
CLOUD_NAME=your_cloud_name
CLOUD_API_KEY=your_api_key
CLOUD_API_SECRET=your_api_secret
```

### 3. Run with Docker Compose

```bash
docker compose up --build
```

Access the app at **http://localhost/**

### Manual setup (without Docker)

```bash
# Terminal 1 - MongoDB
docker run -d --name my-mongo -p 27017:27017 -v mongo-data:/data/db mongo:latest

# Terminal 2 - Auth
cd backend/auth && npm install && npm start

# Terminal 3 - Discounts
cd backend/discounts && npm install && npm start

# Terminal 4 - Items
cd backend/items && npm install && npm start

# Terminal 5 - Frontend
cd client && npm install && npm start

# Terminal 6 - HAProxy
haproxy -f haproxy.cfg
```

---

## Production Deployment (AKS)

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) logged in via `az login`
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) >= 3

### Step 1 — Provision AKS

```bash
cd terraform
terraform init
terraform apply
```

Connect kubectl:

```bash
az aks get-credentials --resource-group hagen-restauranty-rg --name restauranty-aks
```

### Step 2 — Install NGINX Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

Get the public IP:

```bash
kubectl get service ingress-nginx-controller -n ingress-nginx
```

### Step 3 — Create Namespace & Secrets

```bash
kubectl apply -f k8s/namespace.yaml

kubectl create secret generic restauranty-secrets \
  --namespace restauranty \
  --from-literal=SECRET="MySecret1!" \
  --from-literal=MONGODB_URI="mongodb://mongo-service:27017/restauranty" \
  --from-literal=CLOUD_NAME="your_cloud_name" \
  --from-literal=CLOUD_API_KEY="your_api_key" \
  --from-literal=CLOUD_API_SECRET="your_api_secret"
```

### Step 4 — Deploy Workloads

```bash
kubectl apply -R -f k8s/
```

### Step 5 — Install Monitoring

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/values.yaml
```

Access Grafana:

```bash
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
# http://localhost:3000  (admin / ChangeMe!)
```

---

## Environment Variables

| Variable               | Description                                 |
| ---------------------- | ------------------------------------------- |
| `SECRET`               | JWT signing key                             |
| `MONGODB_URI`          | MongoDB connection string                   |
| `CLOUD_NAME`           | Cloudinary cloud name                       |
| `CLOUD_API_KEY`        | Cloudinary API key                          |
| `CLOUD_API_SECRET`     | Cloudinary API secret                       |
| `PORT`                 | Service port (3001 / 3002 / 3003)           |
| `REACT_APP_SERVER_URL` | Frontend API base URL (empty in production) |

---

## Tech Stack

- **Frontend**: React 18, React Router 6, Axios
- **Backend**: Node.js, Express, Mongoose, JWT, bcryptjs
- **Image Storage**: Cloudinary (multer-storage-cloudinary)
- **Monitoring**: Prometheus metrics (`/metrics` on each backend) + Grafana
- **Routing**: HAProxy (local) / NGINX Ingress (production)
- **Database**: MongoDB 7 with Azure Disk persistent storage
- **Orchestration**: Kubernetes (AKS) provisioned via Terraform
- **Container Registry**: Docker Hub

---

## Useful Commands

```bash
# View logs for a service
kubectl logs -l app=auth -n restauranty --tail=100

# Check all pods
kubectl get pods -n restauranty

# Restart a deployment
kubectl rollout restart deployment/auth -n restauranty

# Check ingress
kubectl describe ingress restauranty-ingress -n restauranty
```

---

## Security

See [SECURITY.md](./SECURITY.md) for details on secret management, network security, authentication, and compliance.
# CI/CD test
