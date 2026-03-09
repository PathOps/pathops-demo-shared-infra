# Vault installation

## Install

```bash
cd bootstrap/vault
./apply.sh
```

## Initialize

```bash
kubectl -n vault exec -it statefulset/vault -- sh
export VAULT_ADDR=http://127.0.0.1:8200
vault operator init
vault operator unseal
vault login
vault secrets enable -path=kv kv-v2
```

## Bootstrap secrets

```bash
vault kv put kv/pathops/shared/keycloak \
  KEYCLOAK_ADMIN=admin \
  KEYCLOAK_ADMIN_PASSWORD='change-me-now'

vault kv put kv/pathops/shared/postgres \
  POSTGRES_DB=keycloak \
  POSTGRES_USER=keycloak \
  POSTGRES_PASSWORD='change-me'
```
