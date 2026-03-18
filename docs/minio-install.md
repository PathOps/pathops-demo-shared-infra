# MinIO installation

## Purpose

MinIO provides S3-compatible object storage for the PathOps demo.

Typical demo uses:
- evidence snapshots
- large payloads
- patch bundles
- logs or exported artifacts when needed

## Prerequisites

- MicroK8s installed on vm04-k8s-shared
- Storage enabled
- Ingress enabled
- Local secrets created in `.secrets/`

## Required local files

- `.secrets/minio.env`

## Install

```bash
cd bootstrap/minio
./apply.sh
```

## Verify

```bash
kubectl -n minio get secret
kubectl -n minio get pods
kubectl -n minio get svc
kubectl -n minio get pvc
kubectl -n minio get ingress
kubectl -n minio logs statefulset/minio
```

## Access

API:
`https://minio.demo.pathops.io`

Console:
`https://minio-console.demo.pathops.io`
