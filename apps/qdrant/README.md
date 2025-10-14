# Qdrant Vector Database Deployment

This directory contains the configuration for deploying Qdrant using the official Helm chart with ArgoCD.

## Overview

Qdrant is deployed using:
- **Helm Chart**: Official Qdrant Helm chart from https://qdrant.github.io/qdrant-helm
- **Version**: 0.8.4
- **Authentication**: API key authentication for Qdrant + Basic Auth via Traefik middleware
- **Storage**: Longhorn persistent storage (1Gi)
- **Ingress**: Traefik IngressRoute with TLS

## Files

- **application.yaml**: ArgoCD Application definition using Helm chart
- **values.yaml**: Helm chart values configuration
- **.secrets.yaml**: Template for creating secrets (DO NOT COMMIT with real values)
- **qdrant-secrets-sealed.yaml**: Sealed secrets for production use
- **middlewares.yaml**: Traefik middleware for basic auth and IngressRoute
- **collection-config.yaml**: ConfigMap for collection initialization
- **collection-init-job.yaml**: Job to create initial collections

## Setup Instructions

### 1. Generate Secrets

#### Generate API Key
```bash
# Generate a secure 64-character hex API key
openssl rand -hex 32
```

#### Generate Basic Auth Credentials
```bash
# Generate htpasswd entry
echo "admin:$(openssl passwd -apr1 'your-password')" | base64

# Or use htpasswd if available
htpasswd -nb admin your-password | base64
```

### 2. Update .secrets.yaml

Edit [`apps/qdrant/.secrets.yaml`](apps/qdrant/.secrets.yaml):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: qdrant-api-key
  namespace: qdrant
type: Opaque
stringData:
  api-key: "YOUR_64_CHAR_API_KEY"
```

### 3. Seal the Secrets

```bash
# Seal the API key secret
kubectl create secret generic qdrant-api-key \
  --from-literal=api-key="YOUR_API_KEY" \
  --namespace=qdrant \
  --dry-run=client -o yaml | \
  kubeseal --format=yaml > temp-apikey.yaml

# Update qdrant-secrets-sealed.yaml with the encrypted data
```

### 4. Deploy with ArgoCD

```bash
# Apply the ArgoCD application
kubectl apply -f apps/qdrant/application.yaml

# Verify deployment
kubectl get pods -n qdrant
kubectl get svc -n qdrant
```

## Configuration

### Helm Values

Key configurations in [`values.yaml`](apps/qdrant/values.yaml):

- **API Key Authentication**: Enabled via environment variable `QDRANT__SERVICE__API_KEY`
- **Resources**: 512Mi-1Gi memory, 200m-500m CPU
- **Persistence**: 1Gi Longhorn storage
- **Security**: Non-root user (1000:1000), dropped capabilities

### Authentication Layers

1. **Traefik Basic Auth**: First layer via middleware
2. **Qdrant API Key**: Second layer for API access

### Accessing Qdrant

#### Internal (within cluster)
```bash
# Without auth (from within namespace)
curl http://qdrant:6333/

# With API key
curl -H "api-key: YOUR_API_KEY" http://qdrant:6333/collections
```

#### External (via ingress)
```bash
# Basic auth + API key required
curl -u admin:password \
  -H "api-key: YOUR_API_KEY" \
  https://qdrant.oisd.io/collections
```

## Collection Initialization

The [`collection-init-job.yaml`](apps/qdrant/collection-init-job.yaml) creates a `code_chunks` collection with:

- **Vector size**: 3584 (for modern embeddings)
- **Distance metric**: Cosine
- **HNSW parameters**: m=16, ef_construct=256
- **Payload schema**: Fields for path, lang, and symbol

To manually run the initialization job:
```bash
kubectl delete job qdrant-collection-init -n qdrant
kubectl apply -f apps/qdrant/collection-init-job.yaml
```

## Troubleshooting

### Check Qdrant logs
```bash
kubectl logs -n qdrant -l app.kubernetes.io/name=qdrant
```

### Check API key authentication
```bash
# Should fail without API key
kubectl exec -n qdrant deploy/qdrant -- curl http://localhost:6333/collections

# Should succeed with API key
kubectl exec -n qdrant deploy/qdrant -- \
  curl -H "api-key: YOUR_API_KEY" http://localhost:6333/collections
```

### Verify persistent volume
```bash
kubectl get pvc -n qdrant
kubectl get pv | grep qdrant
```

### Test basic auth middleware
```bash
# Should return 401 without auth
curl https://qdrant.oisd.io/

# Should succeed with auth
curl -u admin:password https://qdrant.oisd.io/
```

## Backup and Restore

### Create Snapshot
```bash
# Create snapshot via API
curl -X POST -H "api-key: YOUR_API_KEY" \
  http://qdrant:6333/collections/code_chunks/snapshots
```

### Restore from Snapshot
```bash
# Upload and restore snapshot
curl -X PUT -H "api-key: YOUR_API_KEY" \
  -F "snapshot=@/path/to/snapshot.snapshot" \
  http://qdrant:6333/collections/code_chunks/snapshots/upload
```

## Upgrading

To upgrade the Helm chart version:

1. Update the `targetRevision` in [`application.yaml`](apps/qdrant/application.yaml)
2. Review and update [`values.yaml`](apps/qdrant/values.yaml) for any breaking changes
3. ArgoCD will automatically sync the changes

## References

- [Qdrant Documentation](https://qdrant.tech/documentation/)
- [Qdrant Helm Chart](https://github.com/qdrant/qdrant-helm)
- [Qdrant API Reference](https://qdrant.github.io/qdrant/redoc/index.html)