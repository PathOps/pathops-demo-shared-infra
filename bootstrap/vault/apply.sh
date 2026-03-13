#!/usr/bin/env bash
set -euo pipefail

kubectl apply -k .
kubectl -n vault get all
kubectl -n vault get pvc
kubectl -n vault get ingress