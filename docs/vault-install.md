# Vault installation

## Install

```bash
cd bootstrap/vault
./apply.sh
```

## Verify

```bash
kubectl -n vault get pods
kubectl -n vault get svc
kubectl -n vault get pvc
kubectl -n vault get ingress
```

## Initialize

```bash
kubectl -n vault exec -it statefulset/vault -- sh
export VAULT_ADDR=http://127.0.0.1:8200
vault operator init -key-shares=1 -key-threshold=1
vault operator unseal
vault login
vault secrets enable -path=kv kv-v2
```

## Access

* UI: `https://vault.demo.pathops.io`