# Team5 i-veri Deployment

This repository manages the Kubernetes manifests and top-level ArgoCD application for the i-veri service.

## Branch and Environment Policy

- `develop` is for integration review before production deployment.
- `main` is the production GitOps source watched by ArgoCD.
- Runtime settings should stay in Kubernetes ConfigMap/Secret or GitHub Actions build args.
- Do not commit real `.env` files or secret manifests.

## ArgoCD Root Application

```text
argocd/team5-iveri.yaml
```

The root application watches this repository only:

```text
repo: SKALA-TEAM5/deploy
path: k8s
```

ArgoCD syncs these always-on service manifests:

- `k8s/frontend`
- `k8s/backend`
- `k8s/postgres`
- `k8s/minio`
- `k8s/qdrant`
- `k8s/ingress`

Batch Job manifests are stored in `k8s/batch`, but they are not included in the root `k8s/kustomization.yaml`.
Run them from GitHub Actions or manually when ingestion is needed.

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
