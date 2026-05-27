# 1. Provision the cluster
cd terraform
terraform init
terraform apply

# 2. Connect kubectl
az aks get-credentials --resource-group restauranty-rg --name restauranty-aks

# 3. Install NGINX ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# 4. Create namespace + secrets
kubectl apply -f k8s/namespace.yaml
kubectl create secret generic restauranty-secrets \
  --namespace restauranty \
  --from-literal=SECRET='MySecret1!' \
  --from-literal=MONGODB_URI="mongodb://mongo-service:27017/restauranty" \
  --from-literal=CLOUD_NAME="dv4tqueh7" \
  --from-literal=CLOUD_API_KEY="639741712452721" \
  --from-literal=CLOUD_API_SECRET="xXa4jlLwGuXjWyD2dLj7a2PgPe8"

# 5. Deploy everything
kubectl apply -f k8s/mongo/
kubectl apply -f k8s/auth/
kubectl apply -f k8s/discounts/
kubectl apply -f k8s/items/
kubectl apply -f k8s/client/
kubectl apply -f k8s/ingress.yaml

# 6. Verify
kubectl get pods -n restauranty
