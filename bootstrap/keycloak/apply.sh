#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f namespace.yaml

kubectl -n keycloak create secret generic keycloak-secret \
  --from-env-file="$SECRETS_DIR/keycloak.env" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n keycloak create secret generic keycloak-postgres-secret \
  --from-env-file="$SECRETS_DIR/postgres.env" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -k .

kubectl -n keycloak get all