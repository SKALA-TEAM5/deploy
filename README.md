# Team5 i-veri Deployment

This repository manages the Kubernetes manifests and top-level ArgoCD application for the i-veri service.

## Branch and Environment Policy

- `develop` is the integration branch. Local integration tests are based on `develop`.
- `main` is the production GitOps source watched by ArgoCD.
- Avoid direct pushes to `main`; merge to `main` only after `develop` has been verified.
- Runtime settings should stay in Kubernetes ConfigMap/Secret or GitHub Actions build args.
- Do not commit real `.env` files or secret manifests.

Local integration uses Kubernetes shared services through port-forward instead of local DB containers.

```text
PostgreSQL: team5-postgres
Qdrant:     team5-qdrant
Redis:      team5-redis
MinIO:      team5-minio
```

Frontend, backend, Agent, and Vision development should copy each repo's `.env.example` first, then connect to the shared services through port-forward.

## Local Port Forward

Run all shared services on local ports from a single terminal:

```bash
./scripts/port-forward-all.sh
```

The script forwards frontend, backend, FastAPI, Vision, PostgreSQL, Qdrant,
Redis, MinIO, and Argo CD. Press `Ctrl+C` once to stop every forwarding process.
PostgreSQL uses local port `5433` because macOS may already use `5432`.

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
- `k8s/redis`
- `k8s/vision`
- `k8s/ingress`

Vision 모델 파일은 Git에 커밋하지 않습니다. `team5-vision` Pod의 initContainer가 MinIO에서 모델을 내려받아 `/models`에 주입합니다.

```text
safety-files/models/vision/ppe-detector.pt
safety-files/models/vision/safety-net-classifier.pt
```

Batch Job manifests are stored in `k8s/batch`, but they are not included in the root `k8s/kustomization.yaml`.
Run them from GitHub Actions or manually when ingestion is needed.

Database migration Job manifests are stored in `k8s/jobs`, but they are not included in the root `k8s/kustomization.yaml`.
The `SKALA-TEAM5/db` migration workflow checks out this repository and applies the Flyway Job when migrations run.

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

## Monitoring

Prometheus는 Backend의 `/actuator/prometheus`와 FastAPI의 `/metrics`를 수집합니다.
Grafana에는 Backend/FastAPI 기본 대시보드와 `Team5 AI Agent Overview`가 자동 provisioning됩니다.

AI Agent 대시보드와 알림 설정:

```text
k8s/monitoring/grafana-ai-agent-dashboard-configmap.yaml
k8s/monitoring/prometheus-configmap.yaml
```
