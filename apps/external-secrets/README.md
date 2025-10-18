# External Secrets Operator

The External Secrets Operator is a Kubernetes operator that integrates external secret management systems and syncs secrets into Kubernetes.

## Installation

Installed via Helm chart from the official External Secrets repository.

```bash
kubectl apply -f application.yaml
```

## Usage

Used by searxng to access Redis password from the redis namespace via:
- SecretStore: Defines how to access secrets in other namespaces
- ExternalSecret: Creates Kubernetes secrets from external sources

## Configuration

- Chart: external-secrets/external-secrets v0.9.13
- Namespace: external-secrets
- CRDs: Installed automatically
- Auto-sync: Enabled with prune and self-heal
