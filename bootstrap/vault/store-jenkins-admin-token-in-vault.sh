#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$ROOT_DIR/.secrets}"

JENKINS_ENV_FILE="${JENKINS_ENV_FILE:-$SECRETS_DIR/jenkins.env}"
VAULT_ENV_FILE="${VAULT_ENV_FILE:-$SECRETS_DIR/vault.env}"

: "${VAULT_ADDR:=https://vault.demo.pathops.io}"
: "${VAULT_KV_MOUNT:=secret}"
: "${VAULT_SECRET_PATH:=pathops/projector/jenkins}"

if [[ ! -f "$JENKINS_ENV_FILE" ]]; then
  echo "ERROR: missing env file: $JENKINS_ENV_FILE" >&2
  exit 1
fi

if [[ ! -f "$VAULT_ENV_FILE" ]]; then
  echo "ERROR: missing env file: $VAULT_ENV_FILE" >&2
  exit 1
fi

set -a
source "$JENKINS_ENV_FILE"
source "$VAULT_ENV_FILE"
set +a

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: required command not found: $1" >&2
    exit 1
  }
}

require_cmd curl
require_cmd jq

: "${JENKINS_BASE_URL:?Missing JENKINS_BASE_URL}"
: "${JENKINS_USERNAME:?Missing JENKINS_USERNAME}"
: "${JENKINS_API_TOKEN:?Missing JENKINS_API_TOKEN}"
: "${VAULT_ROOT_TOKEN:?Missing VAULT_ROOT_TOKEN}"

ensure_vault_kv_v2_mount() {
  local mounts_json
  mounts_json="$(
    curl -fsS \
      -H "X-Vault-Token: $VAULT_ROOT_TOKEN" \
      "$VAULT_ADDR/v1/sys/mounts"
  )"

  if printf '%s' "$mounts_json" | jq -e --arg m "${VAULT_KV_MOUNT}/" 'has($m)' >/dev/null; then
    return 0
  fi

  echo "Vault mount '${VAULT_KV_MOUNT}/' not found. Creating KV v2 mount..."

  curl -fsS \
    -H "X-Vault-Token: $VAULT_ROOT_TOKEN" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"type":"kv","options":{"version":"2"}}' \
    "$VAULT_ADDR/v1/sys/mounts/$VAULT_KV_MOUNT" >/dev/null
}

store_secret_in_vault() {
  local payload
  payload="$(jq -n \
    --arg username "$JENKINS_USERNAME" \
    --arg api_token "$JENKINS_API_TOKEN" \
    --arg base_url "$JENKINS_BASE_URL" \
    '{
      data: {
        username: $username,
        api_token: $api_token,
        base_url: $base_url
      }
    }'
  )"

  curl -fsS \
    -H "X-Vault-Token: $VAULT_ROOT_TOKEN" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "$payload" \
    "$VAULT_ADDR/v1/$VAULT_KV_MOUNT/data/$VAULT_SECRET_PATH" >/dev/null
}

read_secret_from_vault() {
  curl -fsS \
    -H "X-Vault-Token: $VAULT_ROOT_TOKEN" \
    "$VAULT_ADDR/v1/$VAULT_KV_MOUNT/data/$VAULT_SECRET_PATH"
}

echo "Ensuring Vault KV v2 mount exists..."
ensure_vault_kv_v2_mount

echo "Storing Jenkins credentials in Vault..."
store_secret_in_vault

echo
echo "Stored secret successfully at:"
echo "  ${VAULT_KV_MOUNT}/${VAULT_SECRET_PATH}"
echo
echo "Verifying stored secret:"
read_secret_from_vault | jq .