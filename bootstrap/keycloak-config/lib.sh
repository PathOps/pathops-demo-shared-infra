#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
fi

KC_NS=${KC_NS:-keycloak}
KC_HOME=${KC_HOME:-/tmp/pathops-kcadm}
KC_POD=${KC_POD:-$(kubectl -n "$KC_NS" get pods -l app=keycloak -o jsonpath='{.items[0].metadata.name}')}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: required command not found: $1" >&2
    return 1
  }
}

kc() {
  kubectl -n "$KC_NS" exec -i "$KC_POD" -- sh -lc '
    set +e
    export HOME="'"$KC_HOME"'"
    mkdir -p "$HOME"
    /opt/keycloak/bin/kcadm.sh "$@"
    exit $?
  ' -- "$@"
}

kc_put_file() {
  local local_file="$1"
  local remote_file="$2"

  kubectl -n "$KC_NS" exec -i "$KC_POD" -- sh -lc "cat > '$remote_file'" < "$local_file"
}

kc_rm_file() {
  local remote_file="$1"

  kubectl -n "$KC_NS" exec -i "$KC_POD" -- sh -lc "rm -f '$remote_file'"
}

kc_with_remote_file() {
  local local_file="$1"
  shift

  local remote_file
  remote_file="/tmp/$(basename "$local_file").$$.json"

  kc_put_file "$local_file" "$remote_file"
  kc "$@" -f "$remote_file"
  local rc=$?
  kc_rm_file "$remote_file" >/dev/null 2>&1 || true
  return $rc
}

render_json() {
  local src="$1"
  envsubst < "$src"
}

kc_login() {
  local server="$1"
  local user="$2"
  local pass="$3"

  kc config credentials \
    --server "$server" \
    --realm master \
    --user "$user" \
    --password "$pass" >/dev/null
}

realm_exists() {
  local realm="$1"

  if kc get "realms/$realm" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

create_or_update_realm() {
  local realm="$1"
  local file="$2"
  local payload
  payload="$(mktemp)"

  render_json "$file" > "$payload"

  if realm_exists "$realm"; then
    echo "Updating realm: $realm"
    kc_with_remote_file "$payload" update "realms/$realm"
  else
    echo "Creating realm: $realm"
    kc_with_remote_file "$payload" create realms
  fi
}

ensure_realm_role() {
  local realm="$1"
  local role_name="$2"
  local role_desc="$3"

  if kc get "realms/$realm/roles/$role_name" >/dev/null 2>&1; then
    echo "Role exists: $role_name"
  else
    echo "Creating role: $role_name"
    kc create "realms/$realm/roles" \
      -s "name=$role_name" \
      -s "description=$role_desc"
  fi
}

get_user_id_by_username() {
  local realm="$1"
  local username="$2"

  kc get "realms/$realm/users?username=$username" | jq -r '.[0].id // empty'
}

create_or_update_user() {
  local realm="$1"
  local file="$2"
  local username="$3"
  local payload
  local user_id

  payload="$(mktemp)"
  render_json "$file" > "$payload"

  user_id="$(get_user_id_by_username "$realm" "$username")"

  if [[ -n "$user_id" ]]; then
    echo "Updating user: $username"
    kc_with_remote_file "$payload" update "realms/$realm/users/$user_id"
  else
    echo "Creating user: $username"
    kc_with_remote_file "$payload" create "realms/$realm/users"
  fi
}

set_user_password() {
  local realm="$1"
  local username="$2"
  local password="$3"
  local user_id

  user_id="$(get_user_id_by_username "$realm" "$username")"
  [[ -n "$user_id" ]] || return 1

  kc set-password \
    -r "$realm" \
    --userid "$user_id" \
    --new-password "$password"
}

ensure_user_realm_role() {
  local realm="$1"
  local username="$2"
  local role_name="$3"
  local user_id
  local has_role

  user_id="$(get_user_id_by_username "$realm" "$username")"
  [[ -n "$user_id" ]] || return 1

  has_role="$(
    kc get "realms/$realm/users/$user_id/role-mappings/realm" \
      | jq -r --arg role "$role_name" '.[]? | select(.name==$role) | .name'
  )"

  if [[ "$has_role" == "$role_name" ]]; then
    echo "User $username already has role $role_name"
  else
    echo "Granting role $role_name to $username"
    kc add-roles -r "$realm" --uusername "$username" --rolename "$role_name"
  fi
}

idp_exists() {
  local realm="$1"
  local alias="$2"

  if kc get "realms/$realm/identity-provider/instances/$alias" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

create_or_update_idp() {
  local realm="$1"
  local alias="$2"
  local file="$3"
  local payload

  payload="$(mktemp)"
  render_json "$file" > "$payload"

  if idp_exists "$realm" "$alias"; then
    echo "Updating IdP: $alias"
    kc_with_remote_file "$payload" update "realms/$realm/identity-provider/instances/$alias"
  else
    echo "Creating IdP: $alias"
    kc_with_remote_file "$payload" create "realms/$realm/identity-provider/instances"
  fi
}

get_client_uuid() {
  local realm="$1"
  local client_id="$2"

  kc get "realms/$realm/clients?clientId=$client_id" | jq -r '.[0].id // empty'
}

create_or_update_client() {
  local realm="$1"
  local client_id="$2"
  local file="$3"
  local payload
  local uuid

  payload="$(mktemp)"
  render_json "$file" > "$payload"

  uuid="$(get_client_uuid "$realm" "$client_id")"

  if [[ -n "$uuid" ]]; then
    echo "Updating client: $client_id"
    kc_with_remote_file "$payload" update "realms/$realm/clients/$uuid"
  else
    echo "Creating client: $client_id"
    kc_with_remote_file "$payload" create "realms/$realm/clients"
  fi
}