#!/usr/bin/env bash
set -euo pipefail

SECRETS_DIR="${SECRETS_DIR:-$PWD/.secrets}"
VAULT_FILE="$SECRETS_DIR/vault-init.txt"

if [ ! -f "$VAULT_FILE" ]; then
  echo "Vault init file not found: $VAULT_FILE"
  exit 1
fi

UNSEAL_KEY="$(grep '^Unseal Key 1:' "$VAULT_FILE" | sed 's/^Unseal Key 1:[[:space:]]*//')"

if [ -z "${UNSEAL_KEY:-}" ]; then
  echo "Unseal Key 1 not found in $VAULT_FILE"
  exit 1
fi

kubectl -n vault exec -i statefulset/vault -- sh -c '
  export VAULT_ADDR=http://127.0.0.1:8200
  vault operator unseal "$1"
' sh "$UNSEAL_KEY"