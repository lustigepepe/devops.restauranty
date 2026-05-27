# Security & Compliance

## Secret Management

All sensitive credentials are stored as **Kubernetes Secrets** and never committed to Git.

Secrets are injected into pods at runtime via `envFrom`:

```yaml
envFrom:
  - secretRef:
      name: restauranty-secrets
```

The following secrets are managed this way:

| Secret | Description |
|--------|-------------|
| `SECRET` | JWT signing key |
| `MONGODB_URI` | MongoDB connection string |
| `CLOUD_NAME` | Cloudinary cloud name |
| `CLOUD_API_KEY` | Cloudinary API key |
| `CLOUD_API_SECRET` | Cloudinary API secret |

To create secrets in a new cluster:

```bash
kubectl create secret generic restauranty-secrets \
  --namespace restauranty \
  --from-literal=SECRET="..." \
  --from-literal=MONGODB_URI="..." \
  --from-literal=CLOUD_NAME="..." \
  --from-literal=CLOUD_API_KEY="..." \
  --from-literal=CLOUD_API_SECRET="..."
```

**Never** store real credentials in `secrets.yaml` or any file committed to Git.

---

## Network Security

All microservices use `ClusterIP` — they are internal only and not reachable from the public internet.

Only the NGINX Ingress Controller is exposed via a public `LoadBalancer` IP. All external traffic enters through port 80 and is routed by path:

| Path | Service |
|------|---------|
| `/api/auth/*` | auth-service (ClusterIP) |
| `/api/discounts/*` | discounts-service (ClusterIP) |
| `/api/items/*` | items-service (ClusterIP) |
| `/` | client-service (ClusterIP) |

MongoDB is also `ClusterIP` — only accessible from within the cluster at `mongo-service:27017`.

---

## Authentication & Authorization

- User authentication is handled by the **auth microservice** using **JWT tokens**
- Tokens are signed with the `SECRET` environment variable
- All protected routes in `discounts` and `items` validate the JWT from the `Authorization: Bearer <token>` header
- Every registered user defaults to `role: admin` as defined in the User model

---

## TLS / HTTPS

Currently the app runs on HTTP. For production hardening, TLS can be added via **cert-manager** with a Let's Encrypt certificate:

```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

This would terminate HTTPS at the ingress and redirect all HTTP to HTTPS automatically.

---

## Data Encryption

- MongoDB data is stored on an **Azure Disk (managed-csi)** which is encrypted at rest by default by Azure
- No additional application-level encryption is applied
- Cloudinary handles media storage with its own encryption at rest

---

## IAM & Access Control

- The AKS cluster uses a **SystemAssigned managed identity**
- No hardcoded Azure credentials anywhere in the codebase
- Access to the cluster requires Azure CLI authentication (`az login`) and explicit `az aks get-credentials`

---

## Compliance Notes

This project stores the following personal data in MongoDB:

- Name, surname, email, address, phone number

For GDPR compliance:
- Users can be deleted via the `DELETE /api/auth/users/:id` endpoint
- No data is shared with third parties except Cloudinary (media storage)
- MongoDB data is encrypted at rest via Azure Disk encryption
