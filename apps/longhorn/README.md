# Longhorn Distributed Storage

Longhorn provides distributed block storage for Kubernetes with automatic backups to Garage S3-compatible storage.

## Features

- **Distributed Storage**: Replicated block storage across multiple nodes
- **Automatic Backups**: Daily backups to Garage S3 storage  
- **Snapshots**: Point-in-time volume snapshots
- **Disaster Recovery**: Cross-cluster backup and restore
- **CSI Driver**: Native Kubernetes CSI integration
- **Web UI**: Comprehensive management interface

## Deployment Order

Longhorn should be deployed after Garage for backup functionality:

1. **Traefik first**: Provides ingress for Longhorn UI
2. **Garage second**: Provides S3 storage that Longhorn can use for backups
3. **Longhorn third**: Can immediately use Garage for backups via internal cluster networking

## Network Access

- **Internal cluster access**: Applications can use Longhorn via CSI driver
  - Storage class: `longhorn` 
  - Default storage class for PVCs
- **External access**: Management UI available through Traefik ingress
  - Management UI: `https://longhorn.oisd.io`

## Setup Process

### 1. Prerequisites

Ensure Garage is deployed and running:
```bash
kubectl get pods -n garage
kubectl exec -n garage garage-0 -- /garage status
```

### 2. Deploy Longhorn

```bash
# Deploy Longhorn via ArgoCD
git add apps/longhorn/
git commit -m "Add Longhorn distributed storage"
git push

# Wait for deployment
kubectl wait --for=condition=available deployment/longhorn-ui -n longhorn-system
kubectl get pods -n longhorn-system
```

### 3. Configure Garage Backup Target

The deployment automatically configures Garage as the backup target via:
- **Backup Target**: `s3://homelab-backups@garage/`
- **Credentials**: Managed via sealed secrets referencing Garage admin credentials
- **Endpoint**: Internal cluster service `garage-s3-api.garage.svc.cluster.local:3900`

### 4. Initialize Backup Bucket

The bucket initialization job runs automatically during deployment and:
- Creates the `homelab-backups` bucket in Garage
- Sets appropriate permissions
- Validates connectivity

Check the job status:
```bash
kubectl get jobs -n longhorn-system
kubectl logs -n longhorn-system job/longhorn-bucket-init
```

### 5. Verify Backup Configuration

Access the Longhorn UI to verify backup settings:
```bash
# Check if backup target is configured correctly
kubectl get settings.longhorn.io backup-target -n longhorn-system -o yaml

# Verify credential secret exists
kubectl get secret longhorn-backup-secret -n longhorn-system
```

## Usage Examples

### Creating Volumes

```yaml
# PVC using Longhorn storage
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 10Gi
```

### Taking Snapshots

```bash
# Via Longhorn UI or kubectl
kubectl create -f - <<EOF
apiVersion: longhorn.io/v1beta2
kind: Snapshot
metadata:
  name: my-volume-snapshot
  namespace: longhorn-system
spec:
  volume: pvc-xxxxx
EOF
```

### Backup Operations

```bash
# Create backup (via Longhorn UI or API)
# Backups are automatically stored in Garage S3

# List backups
kubectl exec -n garage garage-0 -- /garage bucket list homelab-backups

# Restore from backup (via Longhorn UI)
```

## Configuration

### Storage Classes

Longhorn provides these storage classes:
- **`longhorn`**: Default class, 1 replica (single-node setup)
- **`longhorn-2`**: 2 replicas (if configured for multi-node)
- **`longhorn-3`**: 3 replicas (if configured for multi-node)

### Backup Settings

Key backup configurations:
```yaml
defaultSettings:
  backupTarget: s3://homelab-backups@garage/
  backupTargetCredentialSecret: longhorn-backup-secret
  backupstorePollInterval: "300" # 5 minutes
  createDefaultDiskLabeledNodes: true
```

### Node Configuration

Longhorn automatically discovers and configures nodes with:
- Available storage paths (usually `/var/lib/longhorn`)
- Disk scheduling and taints
- Replica count based on node availability

## Monitoring & Maintenance

### Health Checks

```bash
# Check Longhorn system health
kubectl get pods -n longhorn-system

# Check volume health
kubectl get volumes.longhorn.io -n longhorn-system

# Check node status
kubectl get nodes.longhorn.io -n longhorn-system

# View Longhorn events
kubectl get events -n longhorn-system --sort-by='.lastTimestamp'
```

### Backup Verification

```bash
# Check backup jobs
kubectl get backups.longhorn.io -n longhorn-system

# Verify backups in Garage
kubectl exec -n garage garage-0 -- /garage bucket list homelab-backups

# Test backup connectivity
kubectl exec -n longhorn-system deployment/longhorn-ui -- curl -I http://garage-s3-api.garage.svc.cluster.local:3900
```

### Performance Monitoring

Access the Longhorn UI at `https://longhorn.oisd.io` to monitor:
- Volume performance metrics
- Node resource usage
- Backup job status and history
- Storage pool utilization

## Troubleshooting

### Common Issues

**Backup target unreachable**:
```bash
# Check Garage service connectivity
kubectl exec -n longhorn-system deployment/longhorn-ui -- nslookup garage-s3-api.garage.svc.cluster.local

# Verify credentials
kubectl get secret longhorn-backup-secret -n longhorn-system -o yaml
```

**Bucket initialization failed**:
```bash
# Check job logs
kubectl logs -n longhorn-system job/longhorn-bucket-init

# Verify Garage credentials exist
kubectl get secret garage-credentials -n garage

# Manually retry bucket creation
kubectl delete job longhorn-bucket-init -n longhorn-system
# Redeploy to trigger job recreation
```

**Volume attachment issues**:
```bash
# Check CSI driver pods
kubectl get pods -n longhorn-system | grep csi

# Check node disk configuration
kubectl describe nodes.longhorn.io -n longhorn-system

# Verify storage class
kubectl get storageclass longhorn -o yaml
```

### Logs

```bash
# Longhorn manager logs
kubectl logs -n longhorn-system daemonset/longhorn-manager

# CSI driver logs  
kubectl logs -n longhorn-system deployment/csi-attacher
kubectl logs -n longhorn-system deployment/csi-provisioner

# UI logs
kubectl logs -n longhorn-system deployment/longhorn-ui
```

## Backup and Disaster Recovery

### Regular Backups

Longhorn can be configured for automatic recurring backups:
1. **Schedule**: Set via Longhorn UI or recurring job CRDs  
2. **Retention**: Configurable retention policies
3. **Cross-cluster**: Backups stored in Garage can be accessed from other clusters

### Disaster Recovery

To restore from Garage backups:
1. **New cluster setup**: Deploy Longhorn with same backup target
2. **Restore volumes**: Use Longhorn UI to restore from available backups
3. **Application recovery**: Redeploy applications with restored volumes

### Migration Between Clusters

```bash
# Export volume as backup
# (via Longhorn UI)

# In target cluster, configure same backup target
# Restore volumes from backup
# Redeploy applications
```

## Security Considerations

- **Sealed Secrets**: Garage credentials stored as sealed secrets
- **Network Policies**: Consider restricting access between namespaces if needed
- **RBAC**: Longhorn uses minimal required permissions
- **Encryption**: Backups are stored unencrypted in Garage (consider client-side encryption if needed)