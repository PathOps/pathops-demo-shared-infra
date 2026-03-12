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
