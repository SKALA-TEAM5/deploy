# Team5 i-veri Deployment

This repository manages the top-level ArgoCD application for the i-veri service.

## Branch and Environment Policy

- `develop` is for integration review before production deployment.
- `main` is the production GitOps source watched by ArgoCD.
- Runtime settings should stay in each service repo's Kubernetes ConfigMap/Secret or GitHub Actions build args.
- Do not commit real `.env` files or secret manifests.

## ArgoCD Root Application

```text
argocd/team5-iveri.yaml
```

The root application currently syncs these service manifests:

- frontend: `SKALA-TEAM5/frontend`, path `k8s`
- backend: `SKALA-TEAM5/backend`, path `k8s`
- PostgreSQL: `SKALA-TEAM5/db`, path `k8s/postgres`
- MinIO: `SKALA-TEAM5/db`, path `k8s/minio`
- Qdrant: `SKALA-TEAM5/qdrant`, path `k8s`
- Ingress: `SKALA-TEAM5/deploy`, path `k8s/ingress`

## Public Endpoints

The service uses the existing `public-nginx` IngressClass.

```text
Frontend: http://team5-iveri.skala25a.project.skala-ai.com
Backend:  http://api-team5-iveri.skala25a.project.skala-ai.com
```

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
