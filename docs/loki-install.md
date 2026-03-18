# Loki installation

## Purpose

Loki provides the log backend for the PathOps demo.

In the demo environment, Loki is one of the optional evidence sources used by the Evidence Collector.

## Prerequisites

- MicroK8s installed on vm04-k8s-shared
- Storage enabled
- Ingress enabled
- MinIO already installed
- Local secrets created in `.secrets/`
- `helm` installed locally
- `envsubst` installed locally

## Required local files

- `.secrets/minio.env`
- `.secrets/loki.env`

## Install

```bash
cd bootstrap/loki
./apply.sh
```

## Verify

```bash
kubectl -n loki get pods
kubectl -n loki get svc
kubectl -n loki get pvc
kubectl -n loki get ingress
kubectl -n loki logs statefulset/loki
```

## Access

Base URL:
`https://loki.demo.pathops.io`

Useful endpoints:

* `/ready`
* `/loki/api/v1/query`
* `/loki/api/v1/query_range`
