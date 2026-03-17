#!/usr/bin/env bash
set -euo pipefail

SECRETS_DIR="${SECRETS_DIR:-$PWD/.secrets}"
VAULT_FILE="$SECRETS_DIR/vault.env"

if [ ! -f "$VAULT_FILE" ]; then
  echo "Vault env file not found: $VAULT_FILE"
  exit 1
fi

set -a
source "$VAULT_FILE"
set +a

if [ -z "${VAULT_ROOT_TOKEN:-}" ]; then
  echo "VAULT_ROOT_TOKEN not found in $VAULT_FILE"
  exit 1
fi

kubectl -n vault exec -i statefulset/vault -- sh -c '
  export VAULT_ADDR=http://127.0.0.1:8200
  vault login "$1"
' sh "$VAULT_ROOT_TOKEN"