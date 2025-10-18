# n8n - Workflow Automation

n8n is a fair-code licensed workflow automation tool that allows you to connect apps and automate workflows.

## Installation

Deployed via Helm chart from 8gears registry:
- **Chart**: oci://8gears.container-registry.com/library/n8n
- **Version**: 1.0.0
- **Namespace**: n8n

```bash
kubectl apply -f application.yaml
```

## Access

- **URL**: https://n8n.oisd.io
- **Ingress**: Traefik with automatic TLS via cert-manager

## Configuration

### Initial Setup

1. On first access, you'll need to create an owner account
2. The encryption key is stored in a Kubernetes secret
3. Workflow data is persisted to a 2Gi PVC

### Important Notes

- **Encryption Key**: Must be set in `main.secret.n8n.encryption_key` before first deployment
  - Generate with: `openssl rand -hex 32`
  - Once set, DO NOT change it or you'll lose access to encrypted credentials
- **Persistence**: Enabled with 2Gi storage for workflow data
- **Mode**: Single-instance (no workers or webhooks)

## Scaling

For production deployments with queue mode:

1. Enable Redis (use existing redis deployment in redis namespace)
2. Enable workers: `worker.enabled: true`
3. Enable webhooks: `webhook.enabled: true`
4. Configure scaling: `scaling.enabled: true`

## Resources

- **Requests**: 100m CPU, 512Mi memory
- **Limits**: 1000m CPU, 1024Mi memory

## Security

- TLS termination via cert-manager with Let's Encrypt
- Security headers via Traefik middleware
- Sensitive data encrypted at rest with encryption key

## Monitoring

Check deployment status:
```bash
kubectl -n n8n get pods
kubectl -n n8n logs -l app.kubernetes.io/name=n8n
```

## Documentation

- [n8n Documentation](https://docs.n8n.io/)
- [Helm Chart Repository](https://github.com/8gears/n8n-helm-chart)
