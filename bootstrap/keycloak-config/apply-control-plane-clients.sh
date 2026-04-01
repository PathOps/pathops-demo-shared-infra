#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$ROOT_DIR/.secrets}"

KEYCLOAK_ENV_FILE="${KEYCLOAK_ENV_FILE:-$SECRETS_DIR/keycloak.env}"
KEYCLOAK_CONFIG_ENV_FILE="${KEYCLOAK_CONFIG_ENV_FILE:-$SECRETS_DIR/keycloak-config.env}"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

if [[ ! -f "$KEYCLOAK_ENV_FILE" ]]; then
  echo "ERROR: missing env file: $KEYCLOAK_ENV_FILE" >&2
  exit 1
fi

if [[ ! -f "$KEYCLOAK_CONFIG_ENV_FILE" ]]; then
  echo "ERROR: missing env file: $KEYCLOAK_CONFIG_ENV_FILE" >&2
  exit 1
fi

set -a
source "$KEYCLOAK_ENV_FILE"
source "$KEYCLOAK_CONFIG_ENV_FILE"
set +a

require_cmd jq
require_cmd envsubst
require_cmd kubectl

: "${KEYCLOAK_URL:?Missing KEYCLOAK_URL}"
: "${KEYCLOAK_REALM:?Missing KEYCLOAK_REALM}"
: "${KEYCLOAK_ADMIN:?Missing KEYCLOAK_ADMIN}"
: "${KEYCLOAK_ADMIN_PASSWORD:?Missing KEYCLOAK_ADMIN_PASSWORD}"

: "${CONTROL_PLANE_BASE_URL:?Missing CONTROL_PLANE_BASE_URL}"
: "${CONTROL_PLANE_PUBLIC_REDIRECT_URIS:?Missing CONTROL_PLANE_PUBLIC_REDIRECT_URIS}"
: "${CONTROL_PLANE_PUBLIC_WEB_ORIGINS:?Missing CONTROL_PLANE_PUBLIC_WEB_ORIGINS}"
: "${CONTROL_PLANE_ADMIN_API_CLIENT_SECRET:?Missing CONTROL_PLANE_ADMIN_API_CLIENT_SECRET}"
: "${CONTROL_PLANE_KEYCLOAK_ADMIN_CLIENT_SECRET:?Missing CONTROL_PLANE_KEYCLOAK_ADMIN_CLIENT_SECRET}"

kc_login "$KEYCLOAK_URL" "$KEYCLOAK_ADMIN" "$KEYCLOAK_ADMIN_PASSWORD"

create_or_update_client \
  "$KEYCLOAK_REALM" \
  "control-plane-public" \
  "$SCRIPT_DIR/desired/clients/control-plane-public.json"

create_or_update_client \
  "$KEYCLOAK_REALM" \
  "control-plane-admin-api" \
  "$SCRIPT_DIR/desired/clients/control-plane-admin-api.json"

create_or_update_client \
  "$KEYCLOAK_REALM" \
  "control-plane-keycloak-admin" \
  "$SCRIPT_DIR/desired/clients/control-plane-keycloak-admin.json"

echo "PathOps Control Plane clients applied successfully."