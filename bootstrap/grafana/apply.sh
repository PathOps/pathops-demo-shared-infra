#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$ROOT_DIR/.secrets}"

ENV_FILE="$SECRETS_DIR/grafana.env"
VALUES_RENDERED="$SCRIPT_DIR/.rendered-values.yaml"

if ! command -v helm >/dev/null 2>&1; then
  echo "helm is required but not installed"
  exit 1
fi

if ! command -v envsubst >/dev/null 2>&1; then
  echo "envsubst is required but not installed (package: gettext-base)"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [ -z "${GRAFANA_ADMIN_USER:-}" ] || [ -z "${GRAFANA_ADMIN_PASSWORD:-}" ]; then
  echo "Missing GRAFANA_ADMIN_USER or GRAFANA_ADMIN_PASSWORD in $ENV_FILE"
  exit 1
fi

kubectl create namespace grafana --dry-run=client -o yaml | kubectl apply -f -

kubectl -n grafana create secret generic grafana-admin \
  --from-literal=admin-user="$GRAFANA_ADMIN_USER" \
  --from-literal=admin-password="$GRAFANA_ADMIN_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

envsubst < "$SCRIPT_DIR/values.yaml.tmpl" > "$VALUES_RENDERED"

helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

helm upgrade --install grafana grafana/grafana \
  -n grafana \
  -f "$VALUES_RENDERED" \
  --wait \
  --timeout 15m

kubectl apply -f "$SCRIPT_DIR/ingress.yaml"

kubectl -n grafana get pods
kubectl -n grafana get svc
kubectl -n grafana get ingress