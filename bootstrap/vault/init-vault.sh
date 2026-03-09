#!/usr/bin/env bash
set -euo pipefail

kubectl -n vault exec -it statefulset/vault -- sh