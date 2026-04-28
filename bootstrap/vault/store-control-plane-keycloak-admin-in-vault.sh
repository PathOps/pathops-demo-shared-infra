#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$ROOT_DIR/.secrets}"

KEYCLOAK_ENV_FILE="${KEYCLOAK_ENV_FILE:-$SECRETS_DIR/keycloak.env}"
KEYCLOAK_CONFIG_ENV_FILE="${KEYCLOAK_CONFIG_ENV_FILE:-$SECRETS_DIR/keycloak-config.env}"
VAULT_ENV_FILE="${VAULT_ENV_FILE:-$SECRETS_DIR/vault.env}"

: "${VAULT_ADDR:=https://vault.demo.pathops.io}"
: "${VAULT_KV_MOUNT:=secret}"
: "${VAULT_SECRET_PATH:=pathops/projector/keycloak-admin}"

if [[ ! -f "$KEYCLOAK_ENV_FILE" ]]; then
  echo "ERROR: missing env file: $KEYCLOAK_ENV_FILE" >&2
  exit 1
fi

if [[ ! -f "$KEYCLOAK_CONFIG_ENV_FILE" ]]; then
  echo "ERROR: missing env file: $KEYCLOAK_CONFIG_ENV_FILE" >&2
  exit 1
fi

if [[ ! -f "$VAULT_ENV_FILE" ]]; then
  echo "ERROR: missing env file: $VAULT_ENV_FILE" >&2
  exit 1
fi

set -a
source "$KEYCLOAK_ENV_FILE"
source "$KEYCLOAK_CONFIG_ENV_FILE"
source "$VAULT_ENV_FILE"
set +a

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: required command not found: $1" >&2
    exit 1
  }
}

require_cmd vault
require_cmd jq
require_cmd kubectl

: "${KEYCLOAK_URL:?Missing KEYCLOAK_URL}"
: "${KEYCLOAK_REALM:?Missing KEYCLOAK_REALM}"
: "${KEYCLOAK_ADMIN:?Missing KEYCLOAK_ADMIN}"
: "${KEYCLOAK_ADMIN_PASSWORD:?Missing KEYCLOAK_ADMIN_PASSWORD}"
: "${CONTROL_PLANE_KEYCLOAK_ADMIN_CLIENT_SECRET:?Missing CONTROL_PLANE_KEYCLOAK_ADMIN_CLIENT_SECRET}"
: "${VAULT_ROOT_TOKEN:?Missing VAULT_ROOT_TOKEN in $VAULT_ENV_FILE}"

CLIENT_ID="control-plane-keycloak-admin"
ISSUER="${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}"
TOKEN_URL="${ISSUER}/protocol/openid-connect/token"
ADMIN_API_BASE_URL="${KEYCLOAK_URL}/admin/realms/${KEYCLOAK_REALM}"

export VAULT_ADDR
export VAULT_TOKEN="$VAULT_ROOT_TOKEN"

get_kc_pod() {
  kubectl -n keycloak get pods -l app=keycloak -o jsonpath='{.items[0].metadata.name}'
}

kc_exec() {
  local pod
  pod="$(get_kc_pod)"

  kubectl -n keycloak exec -i "$pod" -- sh -lc '
    set +e
    export HOME="/tmp/pathops-kcadm"
    mkdir -p "$HOME"
    /opt/keycloak/bin/kcadm.sh "$@"
    exit $?
  ' -- "$@"
}

kc_login() {
  kc_exec config credentials \
    --server "$KEYCLOAK_URL" \
    --realm master \
    --user "$KEYCLOAK_ADMIN" \
    --password "$KEYCLOAK_ADMIN_PASSWORD" >/dev/null
}

get_client_uuid() {
  kc_exec get "realms/${KEYCLOAK_REALM}/clients?clientId=${CLIENT_ID}" \
    | jq -r '.[0].id // empty'
}

echo "Checking Vault status..."
vault status >/dev/null

if ! vault secrets list -format=json | jq -e --arg mount "${VAULT_KV_MOUNT}/" 'has($mount)' >/dev/null; then
  echo "KV mount '${VAULT_KV_MOUNT}/' not found. Enabling KV v2..."
  vault secrets enable -path="$VAULT_KV_MOUNT" -version=2 kv
fi

echo "Resolving Keycloak client UUID..."
kc_login
CLIENT_UUID="$(get_client_uuid)"

if [[ -z "$CLIENT_UUID" ]]; then
  echo "ERROR: Keycloak client not found: ${CLIENT_ID}" >&2
  exit 1
fi

echo "Storing secret at: ${VAULT_KV_MOUNT}/${VAULT_SECRET_PATH}"

vault kv put "${VAULT_KV_MOUNT}/${VAULT_SECRET_PATH}" \
  client_id="$CLIENT_ID" \
  client_uuid="$CLIENT_UUID" \
  client_secret="$CONTROL_PLANE_KEYCLOAK_ADMIN_CLIENT_SECRET" \
  realm="$KEYCLOAK_REALM" \
  issuer="$ISSUER" \
  keycloak_base_url="$KEYCLOAK_URL" \
  token_url="$TOKEN_URL" \
  admin_api_base_url="$ADMIN_API_BASE_URL"

echo
echo "Secret stored successfully."
echo

echo "Stored values:"
vault kv get "${VAULT_KV_MOUNT}/${VAULT_SECRET_PATH}"