#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$ROOT_DIR/.secrets}"

MINIO_ENV="$SECRETS_DIR/minio.env"
LOKI_ENV="$SECRETS_DIR/loki.env"
VALUES_RENDERED="$SCRIPT_DIR/.rendered-values.yaml"

if ! command -v helm >/dev/null 2>&1; then
  echo "helm is required but not installed"
  exit 1
fi

if ! command -v envsubst >/dev/null 2>&1; then
  echo "envsubst is required but not installed (package: gettext-base)"
  exit 1
fi

if [ ! -f "$MINIO_ENV" ]; then
  echo "Missing $MINIO_ENV"
  exit 1
fi

if [ ! -f "$LOKI_ENV" ]; then
  echo "Missing $LOKI_ENV"
  exit 1
fi

set -a
source "$MINIO_ENV"
source "$LOKI_ENV"
set +a

if [ -z "${MINIO_ROOT_USER:-}" ] || [ -z "${MINIO_ROOT_PASSWORD:-}" ]; then
  echo "Missing MinIO credentials in $MINIO_ENV"
  exit 1
fi

if [ -z "${LOKI_S3_BUCKET:-}" ] || [ -z "${LOKI_S3_REGION:-}" ]; then
  echo "Missing Loki S3 settings in $LOKI_ENV"
  exit 1
fi

kubectl apply -f "$SCRIPT_DIR/namespace.yaml"

"$SCRIPT_DIR/create-bucket.sh"

helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update grafana

envsubst < "$SCRIPT_DIR/values.yaml.tmpl" > "$VALUES_RENDERED"

helm upgrade --install loki grafana/loki \
  --namespace loki \
  --create-namespace \
  -f "$VALUES_RENDERED" \
  --wait \
  --timeout 20m

kubectl -n loki get pods
kubectl -n loki get svc
kubectl -n loki get pvc
kubectl -n loki get ingress