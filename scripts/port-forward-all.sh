#!/usr/bin/env bash

set -u

APP_NAMESPACE="${APP_NAMESPACE:-skala3-finalproj-class2-team5}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-skala-argocd}"
LOG_DIR="${TMPDIR:-/tmp}/team5-port-forward"

FORWARDS=(
  "frontend|${APP_NAMESPACE}|service/team5-frontend|3000:3000"
  "backend|${APP_NAMESPACE}|service/team5-backend|8000:8000"
  "fastapi|${APP_NAMESPACE}|service/team5-fastapi|8001:8001"
  "vision|${APP_NAMESPACE}|service/team5-vision|8002:8002"
  "postgres|${APP_NAMESPACE}|service/team5-postgres|5433:5432"
  "qdrant-http|${APP_NAMESPACE}|service/team5-qdrant|6333:6333"
  "qdrant-grpc|${APP_NAMESPACE}|service/team5-qdrant|6334:6334"
  "minio-api|${APP_NAMESPACE}|service/team5-minio|9000:9000"
  "minio-console|${APP_NAMESPACE}|service/team5-minio|9001:9001"
  "argocd|${ARGOCD_NAMESPACE}|service/argocd-server|8080:443"
)

PIDS=()

cleanup() {
  trap - INT TERM EXIT
  if ((${#PIDS[@]})); then
    printf '\n포트포워딩을 종료합니다.\n'
    kill "${PIDS[@]}" 2>/dev/null || true
    wait "${PIDS[@]}" 2>/dev/null || true
  fi
}

trap cleanup INT TERM EXIT

command -v kubectl >/dev/null 2>&1 || {
  echo "kubectl을 찾을 수 없습니다."
  exit 1
}

kubectl cluster-info >/dev/null 2>&1 || {
  echo "Kubernetes 클러스터에 연결할 수 없습니다. kube context를 확인하세요."
  exit 1
}

mkdir -p "${LOG_DIR}"
rm -f "${LOG_DIR}"/*.log

echo "Team5 서비스를 로컬 포트로 연결합니다."
echo "로그 디렉터리: ${LOG_DIR}"
echo

for spec in "${FORWARDS[@]}"; do
  IFS='|' read -r name namespace resource ports <<<"${spec}"
  local_port="${ports%%:*}"

  if lsof -nP -iTCP:"${local_port}" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "[건너뜀] ${name}: localhost:${local_port}가 이미 사용 중입니다."
    continue
  fi

  if ! kubectl get "${resource}" -n "${namespace}" >/dev/null 2>&1; then
    echo "[건너뜀] ${name}: ${namespace}/${resource}를 찾을 수 없습니다."
    continue
  fi

  kubectl port-forward -n "${namespace}" "${resource}" "${ports}" \
    >"${LOG_DIR}/${name}.log" 2>&1 &
  pid=$!
  PIDS+=("${pid}")
  echo "[시작] ${name}: localhost:${local_port} -> ${namespace}/${resource}"
done

sleep 2

failed=0
for pid in "${PIDS[@]}"; do
  if ! kill -0 "${pid}" 2>/dev/null; then
    failed=1
  fi
done

if ((failed)); then
  echo
  echo "일부 포트포워딩이 시작되지 않았습니다. ${LOG_DIR}의 로그를 확인하세요."
fi

echo
echo "주요 접속 주소"
echo "  Frontend      http://localhost:3000"
echo "  Backend       http://localhost:8000"
echo "  FastAPI Docs  http://localhost:8001/docs"
echo "  Vision Docs   http://localhost:8002/docs"
echo "  PostgreSQL    localhost:5433"
echo "  Qdrant        http://localhost:6333/dashboard"
echo "  MinIO Console http://localhost:9001"
echo "  Argo CD       https://localhost:8080"
echo
echo "모두 종료하려면 Ctrl+C를 누르세요."

wait
