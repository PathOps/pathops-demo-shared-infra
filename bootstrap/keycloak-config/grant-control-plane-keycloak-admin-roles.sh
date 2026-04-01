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
require_cmd kubectl

: "${KEYCLOAK_URL:?Missing KEYCLOAK_URL}"
: "${KEYCLOAK_REALM:?Missing KEYCLOAK_REALM}"
: "${KEYCLOAK_ADMIN:?Missing KEYCLOAK_ADMIN}"
: "${KEYCLOAK_ADMIN_PASSWORD:?Missing KEYCLOAK_ADMIN_PASSWORD}"

CLIENT_ID="control-plane-keycloak-admin"
REALM_MANAGEMENT_CLIENT_ID="realm-management"

kc_login "$KEYCLOAK_URL" "$KEYCLOAK_ADMIN" "$KEYCLOAK_ADMIN_PASSWORD"

get_client_uuid_or_fail() {
  local realm="$1"
  local client_id="$2"
  local uuid

  uuid="$(get_client_uuid "$realm" "$client_id")"
  if [[ -z "$uuid" ]]; then
    echo "ERROR: client not found in realm '$realm': $client_id" >&2
    exit 1
  fi

  printf '%s\n' "$uuid"
}

get_service_account_user_id_or_fail() {
  local realm="$1"
  local client_uuid="$2"
  local user_id

  user_id="$(kc get "realms/$realm/clients/$client_uuid/service-account-user" | jq -r '.id // empty')"
  if [[ -z "$user_id" ]]; then
    echo "ERROR: service account user not found for client UUID: $client_uuid" >&2
    exit 1
  fi

  printf '%s\n' "$user_id"
}

role_exists() {
  local realm="$1"
  local client_uuid="$2"
  local role_name="$3"

  kc get "realms/$realm/clients/$client_uuid/roles/$role_name" >/dev/null 2>&1
}

user_has_client_role() {
  local realm="$1"
  local user_id="$2"
  local client_uuid="$3"
  local role_name="$4"

  kc get "realms/$realm/users/$user_id/role-mappings/clients/$client_uuid" \
    | jq -e --arg role "$role_name" '.[]? | select(.name == $role)' >/dev/null 2>&1
}

assign_client_role() {
  local realm="$1"
  local user_id="$2"
  local client_uuid="$3"
  local role_name="$4"

  local role_json tmp
  role_json="$(kc get "realms/$realm/clients/$client_uuid/roles/$role_name")"
  tmp="$(mktemp)"
  printf '[%s]\n' "$role_json" > "$tmp"
  kc_with_remote_file "$tmp" create "realms/$realm/users/$user_id/role-mappings/clients/$client_uuid"
  rm -f "$tmp"
}

ensure_client_role_if_exists() {
  local realm="$1"
  local user_id="$2"
  local client_uuid="$3"
  local role_name="$4"
  local required="${5:-false}"

  if ! role_exists "$realm" "$client_uuid" "$role_name"; then
    if [[ "$required" == "true" ]]; then
      echo "ERROR: required role not found in realm-management: $role_name" >&2
      exit 1
    fi
    echo "Skipping missing optional role: $role_name"
    return 0
  fi

  if user_has_client_role "$realm" "$user_id" "$client_uuid" "$role_name"; then
    echo "Role already assigned: $role_name"
    return 0
  fi

  echo "Assigning role: $role_name"
  assign_client_role "$realm" "$user_id" "$client_uuid" "$role_name"
}

TARGET_CLIENT_UUID="$(get_client_uuid_or_fail "$KEYCLOAK_REALM" "$CLIENT_ID")"
SERVICE_ACCOUNT_USER_ID="$(get_service_account_user_id_or_fail "$KEYCLOAK_REALM" "$TARGET_CLIENT_UUID")"
REALM_MANAGEMENT_UUID="$(get_client_uuid_or_fail "$KEYCLOAK_REALM" "$REALM_MANAGEMENT_CLIENT_ID")"

echo "Target client UUID: $TARGET_CLIENT_UUID"
echo "Service account user ID: $SERVICE_ACCOUNT_USER_ID"
echo "realm-management UUID: $REALM_MANAGEMENT_UUID"
echo

echo "Available realm-management roles:"
kc get "realms/$KEYCLOAK_REALM/clients/$REALM_MANAGEMENT_UUID/roles" | jq -r '.[].name' | sort
echo

# Requeridos
ensure_client_role_if_exists "$KEYCLOAK_REALM" "$SERVICE_ACCOUNT_USER_ID" "$REALM_MANAGEMENT_UUID" "query-users" true
ensure_client_role_if_exists "$KEYCLOAK_REALM" "$SERVICE_ACCOUNT_USER_ID" "$REALM_MANAGEMENT_UUID" "view-users" true
ensure_client_role_if_exists "$KEYCLOAK_REALM" "$SERVICE_ACCOUNT_USER_ID" "$REALM_MANAGEMENT_UUID" "manage-users" true
ensure_client_role_if_exists "$KEYCLOAK_REALM" "$SERVICE_ACCOUNT_USER_ID" "$REALM_MANAGEMENT_UUID" "query-groups" true

# Opcionales
ensure_client_role_if_exists "$KEYCLOAK_REALM" "$SERVICE_ACCOUNT_USER_ID" "$REALM_MANAGEMENT_UUID" "view-clients" false
ensure_client_role_if_exists "$KEYCLOAK_REALM" "$SERVICE_ACCOUNT_USER_ID" "$REALM_MANAGEMENT_UUID" "query-clients" false
echo
echo "Service account roles granted successfully to '$CLIENT_ID'."