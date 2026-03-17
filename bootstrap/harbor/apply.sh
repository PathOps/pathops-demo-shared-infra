#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)/.secrets}"
ENV_FILE="$SECRETS_DIR/harbor.env"
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
  echo "Missing Harbor secrets file: $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [ -z "${HARBOR_ADMIN_PASSWORD:-}" ]; then
  echo "HARBOR_ADMIN_PASSWORD is missing in $ENV_FILE"
  exit 1
fi

if [ -z "${HARBOR_SECRET_KEY:-}" ]; then
  echo "HARBOR_SECRET_KEY is missing in $ENV_FILE"
  exit 1
fi

if [ "${#HARBOR_SECRET_KEY}" -ne 16 ]; then
  echo "HARBOR_SECRET_KEY must be exactly 16 characters"
  exit 1
fi

kubectl apply -f "$SCRIPT_DIR/namespace.yaml"

helm repo add harbor https://helm.goharbor.io >/dev/null 2>&1 || true
helm repo update harbor

envsubst < "$SCRIPT_DIR/values.yaml.tmpl" > "$VALUES_RENDERED"

helm upgrade --install harbor harbor/harbor \
  --namespace harbor \
  --create-namespace \
  -f "$VALUES_RENDERED" \
  --wait \
  --timeout 20m

kubectl -n harbor get pods
kubectl -n harbor get pvc
kubectl -n harbor get ingress