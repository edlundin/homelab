# ArgoCD GitOps Deployment

ArgoCD is a declarative GitOps continuous delivery tool for Kubernetes. It provides automated application deployment, management, and synchronization from Git repositories.

## Features

- **GitOps Workflow**: Declarative deployments from Git repositories
- **Multi-Cluster Management**: Deploy to multiple Kubernetes clusters
- **Application Management**: Web UI and CLI for application lifecycle
- **Automated Sync**: Automatic synchronization with Git repositories
- **Rollback Capabilities**: Easy rollback to previous application states
- **RBAC Integration**: Role-based access control for teams

## Deployment Architecture

ArgoCD is deployed using a bootstrap approach:

1. **Initial Deployment**: Manual deployment via Task command
2. **Self-Management**: ArgoCD manages its own configuration via Git
3. **App-of-Apps Pattern**: Root application manages all other applications
4. **Ingress Access**: External access via Traefik with TLS termination

## Quick Start

### 1. Deploy ArgoCD

After your K3s cluster is running and you have kubeconfig configured:

```bash
# Deploy ArgoCD to the cluster
task deploy-argocd

# Wait for the installation to complete
kubectl get pods -n argocd

# Get the admin password
task get-argocd-password
```

### 2. Bootstrap Applications

Once ArgoCD is running, bootstrap all applications:

```bash
# Deploy the root application (App-of-Apps)
task bootstrap-apps

# Verify applications are syncing
kubectl get applications -n argocd
```

### 3. Access ArgoCD UI

- **URL**: https://argocd.oisd.io
- **Username**: `admin`
- **Password**: Get with `task get-argocd-password`

## App-of-Apps Pattern

The deployment uses the App-of-Apps pattern where ArgoCD manages a root application that discovers and manages all other applications:

```yaml
# Root application scans apps/ directory for application.yaml files
spec:
  source:
    path: apps
    directory:
      recurse: true
      include: "*/application.yaml"
```

This automatically discovers and manages:
- Traefik (ingress controller)
- Garage (S3 storage)
- Longhorn (persistent storage)
- Tailscale (VPN connectivity)
- Any future applications added to `apps/`

## Application Structure

Each application in the `apps/` directory should have:

```
apps/
├── myapp/
│   ├── application.yaml    # ArgoCD Application definition
│   ├── deployment.yaml     # Kubernetes manifests
│   ├── service.yaml        # (or other K8s resources)
│   └── README.md          # Documentation
```

### Example Application Definition

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/edlundin/homelab
    targetRevision: HEAD
    path: apps/myapp
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Configuration

### Sync Policies

All applications use automated sync with:
- **prune**: Remove resources not defined in Git
- **selfHeal**: Automatically correct drift from desired state
- **CreateNamespace**: Automatically create target namespaces

### Security

- **HTTPS Only**: ArgoCD UI accessible only via HTTPS
- **Sealed Secrets**: Secrets managed via sealed-secrets controller
- **RBAC**: Role-based access control (can be configured)
- **Git Authentication**: Uses repository access for security

## Management Tasks

### Available Tasks

```bash
# Deploy ArgoCD initially
task deploy-argocd

# Bootstrap all applications
task bootstrap-apps

# Get admin password
task get-argocd-password

# Generate sealed secrets (when needed)
task generate-sealed-secrets
```

### Common Operations

```bash
# Check application sync status
kubectl get applications -n argocd

# Force sync an application
argocd app sync myapp

# View application details
argocd app get myapp

# Check ArgoCD server status
kubectl get pods -n argocd
```

## Troubleshooting

### Common Issues

**ArgoCD pods not starting**:
```bash
# Check pod status and logs
kubectl get pods -n argocd
kubectl logs -n argocd deployment/argocd-server

# Verify sealed secrets controller is running
kubectl get pods -n kube-system | grep sealed-secrets
```

**Applications not syncing**:
```bash
# Check application status
kubectl describe application myapp -n argocd

# Verify repository access
kubectl get secret argocd-repo-creds -n argocd

# Check ArgoCD server logs
kubectl logs -n argocd deployment/argocd-repo-server
```

**Sync failures**:
```bash
# View application events
kubectl get events -n argocd --sort-by='.lastTimestamp'

# Check specific application logs
argocd app logs myapp

# Manually sync application
argocd app sync myapp --prune
```

### Reset ArgoCD

If you need to reset ArgoCD completely:

```bash
# Delete ArgoCD namespace (this will remove all applications)
kubectl delete namespace argocd

# Redeploy
task deploy-argocd
task bootstrap-apps
```

## Monitoring

### Health Checks

ArgoCD provides health status for all managed applications:
- **Healthy**: All resources are running correctly
- **Progressing**: Deployment/update in progress
- **Degraded**: Some resources are not healthy
- **Suspended**: Application sync is paused

### Sync Status

- **Synced**: Git state matches cluster state
- **OutOfSync**: Git has changes not applied to cluster
- **Unknown**: Unable to determine sync status

### Accessing Logs

```bash
# ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server

# Repository server logs (for Git connectivity)
kubectl logs -n argocd deployment/argocd-repo-server

# Application controller logs
kubectl logs -n argocd deployment/argocd-application-controller
```

## Best Practices

1. **Git as Source of Truth**: Always make changes via Git commits
2. **Automated Sync**: Use automated sync for production applications
3. **Health Checks**: Implement proper readiness/liveness probes
4. **Resource Limits**: Set appropriate resource requests and limits
5. **Monitoring**: Monitor application health and sync status
6. **Backup**: Regularly backup ArgoCD configuration and secrets

## Integration

ArgoCD integrates with other homelab components:

- **Traefik**: Provides ingress and TLS termination
- **Sealed Secrets**: Manages encrypted secrets in Git
- **Longhorn**: Provides persistent storage for ArgoCD
- **Tailscale**: Enables secure remote access to ArgoCD UI

## Upgrading

To upgrade ArgoCD:

1. Update the manifest URL in `apps/argocd/argocd.yaml`
2. Commit and push changes
3. ArgoCD will sync and apply the update automatically
4. Monitor the upgrade process in the ArgoCD UI