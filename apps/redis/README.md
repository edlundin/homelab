# Redis Deployment (Helm + ArgoCD)

This folder manages the deployment of Redis in the homelab Kubernetes cluster using the Bitnami Redis Helm chart, orchestrated by ArgoCD.

## How it works
- **Deployment:** Managed by the Bitnami Redis Helm chart (see `application.yaml`).
- **Configuration:** All custom settings are in `values.yaml`.
- **ArgoCD:** The `application.yaml` defines a multi-source ArgoCD Application, syncing the Helm chart and any additional manifests if needed.

## Files
- `application.yaml` — ArgoCD Application definition for Redis (uses Bitnami Helm chart)
- `values.yaml` — Custom values for the Helm chart (persistence, auth, metrics, etc.)

## Not used
- `redis.yaml` and `redis-service.yaml` are deprecated and should be deleted. All resources are now managed by the Helm chart.

## Usage
- To update configuration, edit `values.yaml` and sync the ArgoCD application.
- Passwords/secrets should be managed via Kubernetes secrets referenced in `values.yaml`.

## References
- [Bitnami Redis Helm Chart](https://artifacthub.io/packages/helm/bitnami/redis)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)