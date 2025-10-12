# Traefik Ingress Controller

Traefik provides ingress controller and load balancer functionality for the Kubernetes cluster using the official Helm chart.

## Features

- **Ingress Controller**: Routes external traffic to Kubernetes services
- **TLS Termination**: Automatic HTTPS via cert-manager certificates  
- **Load Balancing**: Distributes traffic across multiple service instances
- **Dashboard**: Web UI for monitoring and configuration
- **Metrics**: Prometheus metrics integration
- **Auto-Discovery**: Automatically discovers services and ingresses

## Architecture

Traefik is deployed using the official Helm chart with:
- **LoadBalancer Service**: Exposes HTTP (80) and HTTPS (443) ports
- **Dashboard Service**: Internal dashboard on port 9000
- **IngressClass**: Set as default ingress class for the cluster
- **RBAC**: Proper service account and cluster role permissions

## Deployment Structure

```
apps/traefik/
├── application.yaml           # ArgoCD application (Helm chart)
├── dashboard-ingress.yaml     # Dashboard ingress and auth
├── middlewares.yaml          # Additional Traefik middlewares (if any)
└── README.md                 # This documentation
```

## Quick Start

### 1. Prerequisites

- Kubernetes cluster with LoadBalancer support (or MetalLB)
- cert-manager deployed for TLS certificates
- ArgoCD for GitOps deployment

### 2. Deploy Traefik

Traefik deploys automatically via ArgoCD:

```bash
# Sync via ArgoCD
kubectl get applications -n argocd traefik

# Verify deployment
kubectl get pods -n traefik
kubectl get svc -n traefik
```

### 3. Access Dashboard

- **URL**: `https://proxy.oisd.io`
- **Authentication**: Basic auth (admin/admin - change this!)
- **Features**: View routes, services, middlewares, and metrics

## Configuration

### Helm Values

Key configuration options in `application.yaml`:

```yaml
# Load balancer service
service:
  type: LoadBalancer

# Entry points with HTTP→HTTPS redirect  
ports:
  web:
    redirectTo:
      port: websecure
      scheme: https
  websecure:
    tls:
      enabled: true

# Kubernetes providers
providers:
  kubernetesIngress:
    publishedService:
      enabled: true
  kubernetesCRD:
    allowCrossNamespace: true

# Default ingress class
ingressClass:
  enabled: true
  isDefaultClass: true
```

### Dashboard Authentication

Update the dashboard credentials by regenerating the secret:

```bash
# Generate new htpasswd entry
htpasswd -nb admin <new-password> | base64 -w 0

# Update the secret in dashboard-ingress.yaml
kubectl patch secret traefik-auth-secret -n traefik -p='{"data":{"users":"<new-base64-value>"}}'
```

## Usage Examples

### Basic Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: my-app
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  ingressClassName: traefik
  rules:
    - host: myapp.oisd.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
  tls:
    - hosts:
        - myapp.oisd.io
      secretName: wildcard-tls-oisd
```

### Using Middlewares

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: my-app-auth@kubernetescrd
spec:
  # ... rest of ingress config

---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: my-app-auth
  namespace: my-app
spec:
  basicAuth:
    secret: my-app-auth-secret
```

## Monitoring

### Health Checks

```bash
# Check Traefik pods
kubectl get pods -n traefik

# Check service status
kubectl get svc -n traefik

# Check ingresses
kubectl get ingress -A
```

### Dashboard Metrics

Access the dashboard at `https://proxy.oisd.io` to view:
- **Routes**: All configured ingress routes
- **Services**: Backend service health
- **Middlewares**: Applied request/response processors  
- **TLS**: Certificate status and configuration

### Prometheus Metrics

Traefik exposes metrics on port 9100:

```bash
# Port forward to access metrics
kubectl port-forward -n traefik svc/traefik 9100:9100

# Access metrics
curl http://localhost:9100/metrics
```

## Troubleshooting

### Common Issues

**Traefik not starting**:
```bash
# Check pod logs
kubectl logs -n traefik deployment/traefik

# Check configuration
kubectl get configmap -n traefik
```

**Ingress not working**:
```bash
# Check ingress status
kubectl describe ingress <ingress-name> -n <namespace>

# Check Traefik routes
# Access dashboard or check logs
kubectl logs -n traefik deployment/traefik | grep -i route
```

**TLS certificate issues**:
```bash
# Check certificate status
kubectl get certificates -A

# Verify TLS secret exists
kubectl get secret <tls-secret> -n <namespace>
```

### Dashboard Access Issues

**Authentication failing**:
```bash
# Check auth secret
kubectl get secret traefik-auth-secret -n traefik -o yaml

# Verify middleware is applied
kubectl describe ingress traefik-dashboard -n traefik
```

**502/503 errors**:
```bash
# Check Traefik service endpoints
kubectl get endpoints -n traefik

# Verify dashboard is enabled in Helm values
# Should see api.dashboard: true in application.yaml
```

## Security Considerations

- **Dashboard Access**: Protected by basic auth and TLS
- **RBAC**: Traefik uses minimal required cluster permissions
- **TLS**: All traffic encrypted via cert-manager certificates
- **Network Policies**: Consider restricting access between namespaces
- **Resource Limits**: CPU and memory limits configured

## Maintenance

### Upgrading Traefik

Update the chart version in `application.yaml`:

```yaml
source:
  repoURL: https://traefik.github.io/charts
  targetRevision: "32.2.0"  # New version
  chart: traefik
```

### Configuration Changes

Modify Helm values in `application.yaml` and ArgoCD will automatically apply:

```bash
# Check sync status
kubectl get applications -n argocd traefik

# Force sync if needed
argocd app sync traefik
```

## Migration Notes

This deployment migrated from custom YAML manifests to the official Helm chart for:
- **Better maintenance**: Regular updates from Traefik team
- **Production hardening**: Security and RBAC best practices
- **Simplified configuration**: Standard Helm values approach
- **Community support**: Well-documented and tested