# Keycloak installation

## Prerequisites
- MicroK8s installed on vm04-k8s-shared
- Storage enabled
- Ingress enabled
- Local secrets created in `.secrets/`

## Required local files
- `.secrets/keycloak.env`
- `.secrets/postgres.env`

## Install

```bash
cd bootstrap/keycloak
./apply.sh
```

## Verify
```bash
kubectl -n keycloak get secret
kubectl -n keycloak get pods
kubectl -n keycloak get svc
kubectl -n keycloak get ingress
kubectl -n keycloak logs deploy/keycloak
```

## Access

```
URL: http://keycloak.demo.pathops.io
```