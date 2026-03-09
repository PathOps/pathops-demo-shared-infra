#!/usr/bin/env bash
set -euo pipefail

kubectl apply -k .
echo "Install External Secrets Operator separately from official manifests."
kubectl get pods -n external-secrets