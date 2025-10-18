# cert-manager (Helm + ArgoCD)

This directory manages the deployment of cert-manager and its certificate resources in the homelab Kubernetes cluster using the official Jetstack Helm chart, orchestrated by ArgoCD.

## Overview
- **Controller Deployment:** cert-manager is installed and managed via the official Helm chart, with ArgoCD handling lifecycle and upgrades.
- **Custom Resources:** All certificate and issuer resources (wildcard certs, ClusterIssuers) are defined in `cert-manager.yaml` and applied automatically after the controller is ready.
- **Secrets:** DNS provider credentials and other sensitive data are managed in `.secrets.yaml` (should be sealed or managed securely).

## File Structure
- `application.yaml` — ArgoCD Application definition (multi-source: Helm chart for controller, YAML for custom resources)
- `cert-manager.yaml` — Custom resources: wildcard Certificates for all required subdomains, ClusterIssuers for Let's Encrypt (production and staging)
- `.secrets.yaml` — Secrets for DNS provider API tokens, etc. (should be encrypted or sealed)

## How it Works
1. **ArgoCD** deploys cert-manager using the Helm chart from the Jetstack repository.
2. **Helm** manages the cert-manager controller, CRDs, and webhooks in the `cert-manager` namespace.
3. **Custom resources** (Certificates, ClusterIssuers) are applied by ArgoCD after the controller is available.
4. **Secrets** are referenced by ClusterIssuers for DNS-01 challenges (e.g., Cloudflare API tokens).
5. **Wildcard certificates** are issued for all required domains (e.g., `*.oisd.io`, `*.bos.oisd.io`, `*.s3.oisd.io`) and stored as Kubernetes secrets for use by Ingress controllers like Traefik.

## Managing Certificates
- To add or update a certificate or issuer, edit `cert-manager.yaml` and sync the ArgoCD application.
- To update cert-manager itself, change the Helm chart version in `application.yaml`.
- To update secrets, edit `.secrets.yaml` and re-seal if using Sealed Secrets.

## Notes
- All legacy/manual install scripts and manifests have been removed. Only Helm and ArgoCD are used for deployment and management.
- The Helm chart manages all controller components; custom resources are layered on top.
- Ensure your DNS provider credentials are kept secure and up to date.

## References
- [cert-manager Helm Chart](https://artifacthub.io/packages/helm/cert-manager/cert-manager)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)