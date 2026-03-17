# Harbor installation

## Purpose

Harbor is the shared container registry for the PathOps demo.

In the Golden Path demo:
- Jenkins builds images
- Jenkins pushes images to Harbor
- Argo CD deploys workloads using those images

## Prerequisites

- MicroK8s installed on vm04-k8s-shared
- Storage enabled
- Ingress enabled
- Default TLS configured in the ingress controller
- Local secrets created in `.secrets/`
- `helm` installed locally
- `envsubst` installed locally

## Required local file

- `.secrets/harbor.env`

Example:

```bash
cp .secrets.example/harbor.env .secrets/harbor.env
chmod 600 .secrets/harbor.env
```

## Install

```bash
cd bootstrap/harbor
./apply.sh
```

## Verify

```bash
kubectl -n harbor get pods
kubectl -n harbor get pvc
kubectl -n harbor get ingress
kubectl -n harbor get svc
```

## Access

UI:
`https://harbor.demo.pathops.io`

Default user:
`admin`

Password:
from `.secrets/harbor.env`