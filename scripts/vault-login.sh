#!/usr/bin/env bash
set -euo pipefail

SECRETS_DIR="${SECRETS_DIR:-$PWD/.secrets}"
VAULT_FILE="$SECRETS_DIR/vault-init.txt"

if [ ! -f "$VAULT_FILE" ]; then
  echo "Vault init file not found: $VAULT_FILE"
  exit 1
fi

ROOT_TOKEN="$(grep '^Initial Root Token:' "$VAULT_FILE" | sed 's/^Initial Root Token:[[:space:]]*//')"

if [ -z "${ROOT_TOKEN:-}" ]; then
  echo "Initial Root Token not found in $VAULT_FILE"
  exit 1
fi

kubectl -n vault exec -i statefulset/vault -- sh -c '
  export VAULT_ADDR=http://127.0.0.1:8200
  vault login "$1"
' sh "$ROOT_TOKEN"