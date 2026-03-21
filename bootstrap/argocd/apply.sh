#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$ROOT_DIR/.secrets}"

ENV_FILE="$SECRETS_DIR/argocd.env"
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

if [ -z "${ARGOCD_ADMIN_PASSWORD_BCRYPT:-}" ] || [ -z "${ARGOCD_ADMIN_PASSWORD_MTIME:-}" ]; then
  echo "Missing ARGOCD_ADMIN_PASSWORD_BCRYPT or ARGOCD_ADMIN_PASSWORD_MTIME in $ENV_FILE"
  exit 1
fi

kubectl apply -f "$SCRIPT_DIR/namespace.yaml"

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update

envsubst < "$SCRIPT_DIR/values.yaml.tmpl" > "$VALUES_RENDERED"

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f "$VALUES_RENDERED" \
  --wait \
  --timeout 20m

kubectl apply -f "$SCRIPT_DIR/ingress.yaml"

kubectl -n argocd get pods
kubectl -n argocd get svc
kubectl -n argocd get ingress