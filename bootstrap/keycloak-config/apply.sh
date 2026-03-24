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

kc_login "$KEYCLOAK_URL" "$KEYCLOAK_ADMIN" "$KEYCLOAK_ADMIN_PASSWORD"

create_or_update_realm \
  "$KEYCLOAK_REALM" \
  "$SCRIPT_DIR/desired/realm.json"

ensure_realm_role \
  "$KEYCLOAK_REALM" \
  "pathops_admin" \
  "PathOps realm administrator"

create_or_update_user \
  "$KEYCLOAK_REALM" \
  "$SCRIPT_DIR/desired/users/pathops-admin.json" \
  "$PATHOPS_ADMIN_USERNAME"

set_user_password \
  "$KEYCLOAK_REALM" \
  "$PATHOPS_ADMIN_USERNAME" \
  "$PATHOPS_ADMIN_PASSWORD"

ensure_user_realm_role \
  "$KEYCLOAK_REALM" \
  "$PATHOPS_ADMIN_USERNAME" \
  "pathops_admin"

create_or_update_idp \
  "$KEYCLOAK_REALM" \
  "google" \
  "$SCRIPT_DIR/desired/identity-providers/google.json"

create_or_update_client \
  "$KEYCLOAK_REALM" \
  "gitlab" \
  "$SCRIPT_DIR/desired/clients/gitlab.json"

create_or_update_client \
  "$KEYCLOAK_REALM" \
  "jenkins" \
  "$SCRIPT_DIR/desired/clients/jenkins.json"

echo "Keycloak realm configuration applied successfully."