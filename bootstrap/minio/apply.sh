#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f namespace.yaml

kubectl -n minio create secret generic minio-secret \
  --from-env-file="$SECRETS_DIR/minio.env" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -k .

kubectl -n minio get pods
kubectl -n minio get svc
kubectl -n minio get pvc
kubectl -n minio get ingress