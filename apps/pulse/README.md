# Pulse - Proxmox Infrastructure Monitoring

Pulse provides real-time monitoring for Proxmox VE, Proxmox Backup Server, and Docker infrastructure.

## Installation

Deployed via Helm chart from GitHub Container Registry:
- **Chart**: oci://ghcr.io/rcourtman/pulse-chart
- **Version**: 1.0.15
- **Namespace**: pulse

```bash
kubectl apply -f application.yaml
```

## Access

- **URL**: https://pulse.oisd.io
- **Port**: 7655
- **Ingress**: Traefik with automatic TLS via cert-manager

## Initial Setup

1. Access https://pulse.oisd.io on first launch
2. Complete the mandatory security setup wizard
3. Create admin username and password
4. Generate API tokens for automation (Settings → Security → API tokens)

## Node Configuration

### Quick Setup (Interactive)
1. Go to Settings → Nodes in Pulse UI
2. Discovered Proxmox nodes appear automatically
3. Click "Setup Script" next to any node
4. Click "Generate Setup Code" (6-character code, valid 5 minutes)
5. Copy and run the one-liner on your Proxmox/PBS host

Example:
```bash
curl -sSL "http://pulse.pulse.svc.cluster.local:7655/api/setup-script?type=pve&host=https://pve:8006&auth_token=ABC123" | bash
```

### Automated Setup (Ansible/Scripts)
Use permanent API tokens for automation:

```bash
# For Proxmox VE
curl -sSL "http://pulse.pulse.svc.cluster.local:7655/api/setup-script?type=pve&host=https://pve:8006&auth_token=YOUR_API_TOKEN" | bash

# For Proxmox Backup Server
curl -sSL "http://pulse.pulse.svc.cluster.local:7655/api/setup-script?type=pbs&host=https://pbs:8007&auth_token=YOUR_API_TOKEN" | bash
```

## Features

- **Auto-Discovery**: Automatically finds Proxmox nodes on network (192.168.0.0/16 by default)
- **Live Monitoring**: Real-time status of VMs, containers, nodes, storage
- **Smart Alerts**: Email, Discord, Slack, Telegram, Teams, ntfy.sh, Gotify webhooks
- **Backup Management**: Unified view of PBS backups, PVE backups, snapshots
- **Ceph Awareness**: Automatic Ceph health and pool monitoring
- **Docker Support**: Optional Docker container monitoring via lightweight agent
- **Security**: Credentials encrypted at rest, CSRF protection, rate limiting

## Configuration

### Alert Destinations
Configure in **Settings → Alerts → Email/Webhook Destinations**

### Thresholds
- **Settings → Alerts → Custom Rules**: Permanent alert policies
- **Resource Cards**: Quick temporary threshold overrides

### Network Discovery
Default: 192.168.0.0/16 (home networks)
To customize, update `DISCOVERY_SUBNET` in application.yaml

## Storage

- **Persistence**: 5Gi PVC for configuration and historical data
- **Location**: /data (nodes.enc, system.json, .env)

## Resources

- **Requests**: 100m CPU, 256Mi memory  
- **Limits**: 500m CPU, 512Mi memory

## Security

- Mandatory authentication on first access
- Credentials encrypted with AES-256-GCM
- API tokens for automation
- Proxy/SSO support available (Authentik, Authelia)

## Monitoring

Check deployment status:
```bash
kubectl -n pulse get pods
kubectl -n pulse logs -l app.kubernetes.io/name=pulse
```

## Troubleshooting

### Cannot login after setup
- Check .env file was created: `kubectl -n pulse exec -it deployment/pulse -- cat /data/.env`
- Verify API tokens in logs: `kubectl -n pulse logs deployment/pulse | grep -i auth`

### VM disk stats show "-"
- Install QEMU Guest Agent in VMs: `apt install qemu-guest-agent`
- Enable in Proxmox VM Options → QEMU Guest Agent
- Restart VM

### Connection issues to Proxmox
- Verify Proxmox API accessible on port 8006/8007
- Check credentials have PVEAuditor role + VM.Monitor permissions
- Review setup script output for errors

## Documentation

- [Official Docs](https://github.com/rcourtman/Pulse)
- [API Reference](https://github.com/rcourtman/Pulse/blob/main/docs/API.md)
- [Webhook Guide](https://github.com/rcourtman/Pulse/blob/main/docs/WEBHOOKS.md)
- [Security Details](https://github.com/rcourtman/Pulse/blob/main/docs/SECURITY.md)
