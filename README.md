# Team5 i-veri Deployment

This repository manages the top-level ArgoCD application for the i-veri service.

## ArgoCD Root Application

```text
argocd/team5-iveri.yaml
```

The root application currently syncs these service manifests:

- frontend: `SKALA-TEAM5/frontend`, path `k8s`
- backend: `SKALA-TEAM5/backend`, path `k8s`
- PostgreSQL: `SKALA-TEAM5/db`, path `k8s/postgres`
- MinIO: `SKALA-TEAM5/db`, path `k8s/minio`

## Apply

```bash
kubectl apply -f argocd/team5-iveri.yaml
```

## Refresh

```bash
kubectl annotate application team5-iveri \
  -n skala-argocd \
  argocd.argoproj.io/refresh=hard \
  --overwrite
```

## Check

```bash
kubectl get application team5-iveri -n skala-argocd
```
