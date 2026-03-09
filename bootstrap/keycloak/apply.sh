#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f namespace.yaml
kubectl apply -k .

kubectl -n keycloak get externalsecret
kubectl -n keycloak get secret
kubectl -n keycloak get all
kubectl -n keycloak get pvc
kubectl -n keycloak get ingress