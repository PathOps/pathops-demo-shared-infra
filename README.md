# pathops-demo-shared-infra

Bootstrap manifests for shared infrastructure in the PathOps demo environment.

## Components
- Vault
- External Secrets Operator
- Keycloak
- PostgreSQL for Keycloak

## Installation order
1. Install Vault
2. Initialize and unseal Vault
3. Write bootstrap secrets to Vault
4. Install External Secrets Operator
5. Create Vault token secret for Kubernetes
6. Install Keycloak and PostgreSQL


## Exact Installation order

### 1. Vault

```bash
cd bootstrap/vault
./apply.sh
```

### 2. Initialize Vault

Inside the pod run:

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault operator init
vault operator unseal
vault login
vault secrets enable -path=kv kv-v2
```

### 3. Load secrets

```bash
vault kv put kv/pathops/shared/keycloak \
  KEYCLOAK_ADMIN=admin \
  KEYCLOAK_ADMIN_PASSWORD='...'

vault kv put kv/pathops/shared/postgres \
  POSTGRES_DB=keycloak \
  POSTGRES_USER=keycloak \
  POSTGRES_PASSWORD='...'
```

### 4. Install ESO

```bash
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml

kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/operator.yaml
```

### 5. Create Vault token for Kubernetes

Create real secret in keycloak namespace :
```bash
kubectl -n keycloak create secret generic vault-token \
  --from-literal=token='...'
```

### 6. Install Keycloak

```bash
cd bootstrap/keycloak
./apply.sh
```

## Notes
- This repository is currently intended for manual bootstrap with kubectl.
- The target model is GitOps reconciliation through Argo CD.
- Plaintext credentials must not be committed to Git.