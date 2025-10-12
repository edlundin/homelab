# cert-manager TLS Certificate Management

cert-manager automatically provisions and manages TLS certificates in Kubernetes using ACME providers like Let's Encrypt. It integrates with DNS providers to handle domain validation challenges.

## Features

- **Automatic Certificate Provisioning**: Automatically obtains certificates from Let's Encrypt
- **DNS Challenge Support**: Uses Cloudflare DNS for domain validation 
- **Certificate Renewal**: Automatically renews certificates before expiration
- **Wildcard Certificates**: Supports wildcard domain certificates
- **Multiple Issuers**: Production and staging Let's Encrypt issuers
- **Cross-Namespace**: Manages certificates across different namespaces

## Architecture

cert-manager consists of several components:
- **Controller**: Main cert-manager controller that handles Certificate resources
- **Webhook**: Validates and mutates cert-manager custom resources
- **CA Injector**: Injects CA bundles into webhooks and API services
- **ACME Solver**: Handles ACME challenge validation

## Deployment Structure

```
apps/cert-manager/
├── cert-manager.yaml           # Main deployment with CRDs and controllers
├── application.yaml            # ArgoCD application definition
├── cloudflare-secret-sealed.yaml  # Encrypted Cloudflare API token
├── .secret.yaml               # Template secret (for reference)
└── README.md                  # This documentation
```

## Quick Start

### 1. Prerequisites

You need a Cloudflare API token with the following permissions:
- Zone:Zone:Read
- Zone:DNS:Edit
- Include all zones for your domain

### 2. Configure Cloudflare API Token

Update the sealed secret with your Cloudflare API token:

```bash
# Edit the plaintext secret template
nano apps/cert-manager/.secret.yaml

# Generate new sealed secret
task generate-sealed-secrets
```

### 3. Deploy cert-manager

cert-manager will be automatically deployed via ArgoCD once committed to Git:

```bash
git add apps/cert-manager/
git commit -m "Add cert-manager for automatic TLS certificates"
git push
```

### 4. Verify Deployment

Check that cert-manager components are running:

```bash
kubectl get pods -n cert-manager
kubectl get clusterissuers
kubectl get certificates -A
```

## Certificate Management

### ClusterIssuers

Two ClusterIssuers are configured:

- **letsencrypt-prod**: Production Let's Encrypt issuer
- **letsencrypt-staging**: Staging issuer for testing

### Wildcard Certificates

Pre-configured wildcard certificates:

- **wildcard-oisd-io**: `*.oisd.io` and `oisd.io`
- **wildcard-bos-oisd-io**: `*.bos.oisd.io` and `bos.oisd.io`
- **wildcard-bos-s3-io**: `*.s3.oisd.io` and `s3.oisd.io`

These certificates are automatically created in the `traefik` namespace and can be referenced by ingresses.

### Using Certificates in Ingresses

#### Method 1: Certificate Resource (Recommended)
```yaml
# Certificate resource (created automatically for wildcards)
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-app-cert
  namespace: my-app
spec:
  secretName: my-app-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - myapp.oisd.io

---
# Ingress using the certificate
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: my-app
spec:
  tls:
  - hosts:
    - myapp.oisd.io
    secretName: my-app-tls
  rules:
  - host: myapp.oisd.io
    # ... rest of ingress config
```

#### Method 2: Ingress Annotations (Automatic)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: my-app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - myapp.oisd.io
    secretName: my-app-tls  # cert-manager will create this
  rules:
  - host: myapp.oisd.io
    # ... rest of ingress config
```

#### Method 3: Cross-Namespace Certificate Reference
```yaml
# Reference existing wildcard certificate from traefik namespace
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: my-app
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  tls:
  - hosts:
    - myapp.oisd.io
    secretName: wildcard-tls-oisd  # Must copy from traefik namespace
  rules:
  - host: myapp.oisd.io
    # ... rest of ingress config
```

## Integration with Traefik

Traefik has been updated to use cert-manager instead of its built-in ACME resolver:

### Changes Made to Traefik:
1. **Removed ACME Configuration**: No longer uses Traefik's certificatesResolvers
2. **Removed Storage PVC**: No longer needs persistent storage for ACME data  
3. **Updated Ingress Annotations**: Uses cert-manager annotations instead of Traefik's certresolver
4. **Certificate References**: References cert-manager managed certificates

### Traefik Dashboard Certificate:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: traefik-dashboard
  namespace: traefik
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - proxy.oisd.io
    secretName: wildcard-tls-oisd
```

## Configuration

### DNS Challenge Configuration

cert-manager uses Cloudflare DNS-01 challenge for domain validation:

```yaml
solvers:
- dns01:
    cloudflare:
      apiTokenSecretRef:
        name: cloudflare-api-token-secret
        key: api-token
  selector:
    dnsNames:
    - "oisd.io"
    - "*.oisd.io"
```

### Certificate Lifecycle

1. **Creation**: Certificate resource created (manually or via ingress annotation)
2. **ACME Order**: cert-manager creates ACME order with Let's Encrypt
3. **DNS Challenge**: Places TXT record in Cloudflare DNS
4. **Validation**: Let's Encrypt validates domain ownership
5. **Certificate Issue**: Certificate issued and stored in Kubernetes secret
6. **Renewal**: Automatically renewed when 1/3 of lifetime remains

## Monitoring

### Certificate Status

```bash
# Check certificate status
kubectl get certificates -A
kubectl describe certificate wildcard-oisd-io -n traefik

# Check certificate details
kubectl get secret wildcard-tls-oisd -n traefik -o yaml

# View certificate expiry
kubectl get certificate wildcard-oisd-io -n traefik -o jsonpath='{.status.notAfter}'
```

### cert-manager Logs

```bash
# cert-manager controller logs
kubectl logs -n cert-manager deployment/cert-manager

# Webhook logs
kubectl logs -n cert-manager deployment/cert-manager-webhook

# CA injector logs  
kubectl logs -n cert-manager deployment/cert-manager-cainjector
```

### ACME Challenge Debugging

```bash
# Check orders and challenges
kubectl get orders -A
kubectl get challenges -A

# Describe failed challenges
kubectl describe challenge <challenge-name> -n <namespace>

# Check ACME account status
kubectl get clusterissuers letsencrypt-prod -o yaml
```

## Troubleshooting

### Common Issues

**Certificate not issued**:
```bash
# Check certificate status
kubectl describe certificate my-cert -n my-namespace

# Check ACME order
kubectl get orders -n my-namespace
kubectl describe order <order-name> -n my-namespace

# Check DNS challenge
kubectl get challenges -n my-namespace
kubectl describe challenge <challenge-name> -n my-namespace
```

**DNS challenge fails**:
```bash
# Verify Cloudflare API token
kubectl get secret cloudflare-api-token-secret -n cert-manager -o yaml

# Check DNS propagation
dig TXT _acme-challenge.yourdomain.com

# Verify Cloudflare permissions
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_TOKEN"
```

**Certificate not renewed**:
```bash
# Check certificate renewal status
kubectl describe certificate my-cert -n my-namespace

# Force renewal (delete secret to trigger renewal)
kubectl delete secret my-cert-tls -n my-namespace
```

### Rate Limiting

Let's Encrypt has rate limits:
- 50 certificates per registered domain per week
- 5 duplicate certificates per week
- Use staging issuer for testing to avoid hitting production limits

```bash
# Use staging issuer for testing
kubectl patch certificate my-cert -n my-namespace --type='merge' \
  -p='{"spec":{"issuerRef":{"name":"letsencrypt-staging"}}}'
```

## Best Practices

1. **Use Staging First**: Test with letsencrypt-staging before production
2. **Wildcard Certificates**: Use wildcards for multiple subdomains
3. **Monitor Expiry**: Set up alerts for certificate expiration
4. **Backup Certificates**: Include certificate secrets in backup strategy
5. **DNS Propagation**: Allow time for DNS propagation in challenges
6. **Resource Limits**: Set appropriate resource limits for cert-manager
7. **RBAC**: Use minimal required permissions for cert-manager

## Security Considerations

- **API Token Security**: Cloudflare API token stored as sealed secret
- **Certificate Storage**: Certificates stored as Kubernetes TLS secrets
- **DNS Permissions**: API token has minimal required DNS permissions
- **Cross-Namespace Access**: Certificates can be referenced across namespaces
- **Renewal Automation**: Reduces exposure from manual certificate management

## Maintenance

### Upgrading cert-manager

```bash
# Update cert-manager version in cert-manager.yaml
# Commit and push changes
git add apps/cert-manager/cert-manager.yaml
git commit -m "Update cert-manager to v1.16.1"
git push

# Monitor upgrade
kubectl get pods -n cert-manager -w
```

### Adding New Domains

1. Update ClusterIssuer selectors if needed
2. Create Certificate resources for new domains
3. Update ingresses to reference new certificates
4. Verify DNS challenge can access new domains via Cloudflare API