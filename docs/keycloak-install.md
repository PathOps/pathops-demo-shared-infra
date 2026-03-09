# Keycloak installation

## Prerequisites
- MicroK8s installed on vm04-k8s-shared
- Storage enabled
- Ingress enabled
- Vault installed and initialized
- External Secrets Operator installed

## Install
```bash
cd bootstrap/keycloak
./apply.sh