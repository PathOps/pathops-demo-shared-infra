#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$ROOT_DIR/.secrets}"

MINIO_ENV="$SECRETS_DIR/minio.env"
LOKI_ENV="$SECRETS_DIR/loki.env"

if [ ! -f "$MINIO_ENV" ]; then
  echo "Missing $MINIO_ENV"
  exit 1
fi

if [ ! -f "$LOKI_ENV" ]; then
  echo "Missing $LOKI_ENV"
  exit 1
fi

set -a
source "$MINIO_ENV"
source "$LOKI_ENV"
set +a

if [ -z "${MINIO_ROOT_USER:-}" ] || [ -z "${MINIO_ROOT_PASSWORD:-}" ]; then
  echo "Missing MinIO credentials in $MINIO_ENV"
  exit 1
fi

if [ -z "${LOKI_S3_BUCKET:-}" ]; then
  echo "Missing LOKI_S3_BUCKET in $LOKI_ENV"
  exit 1
fi

kubectl -n minio run minio-mc-init \
  --rm -i --restart=Never \
  --image=minio/mc:latest \
  --env "MC_HOST_local=http://${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}@minio.minio.svc.cluster.local:9000" \
  --command -- sh -c "
    mc mb --ignore-existing local/${LOKI_S3_BUCKET}
  "