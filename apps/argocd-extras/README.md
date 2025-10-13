# ArgoCD Extras

This directory contains additional ArgoCD configurations that are managed separately from the main ArgoCD deployment.

## Components

- `application.yaml` - ArgoCD Application for managing ArgoCD extras
- `.secrets.yaml` - ArgoCD admin password as external Kubernetes secret (sealed)
- `argocd-secrets-sealed.yaml` - Generated sealed secret
- `argocd-cm-patch.yaml` - ConfigMap patch to reference external password

## Password Management

### ArgoCD Admin Password

The ArgoCD admin password is managed via sealed secrets with external reference:
- **Username**: `admin` 
- **Password**: `Directed5-Overuse8-Carless8-Nest2-Disarray5`
- **Method**: External sealed secret `argocd-admin-password` referenced in `argocd-cm`

### How it Works

1. Password is stored in `.secrets.yaml` as `argocd-admin-password` secret
2. Sealed using kubeseal like other secrets in this repository
3. ArgoCD ConfigMap references the external secret via `admin.passwordMtime: "argocd-admin-password:password"`
4. ArgoCD automatically reads the password from the external secret

This approach uses ArgoCD's native external password support, avoiding conflicts with the built-in `argocd-secret`.

## Usage

To regenerate sealed secrets:
```bash
task generate-sealed-secrets
```

## Notes

- The sealed secret ensures the admin password is consistent across deployments
- The password overrides ArgoCD's randomly generated initial password
- This requires the sealed-secrets controller to be running in the cluster