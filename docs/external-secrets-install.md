# External Secrets Operator installation

## Install CRDs and operator

```bash
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/operator.yaml
```

## Verify

```bash
kubectl get pods -n external-secrets
```