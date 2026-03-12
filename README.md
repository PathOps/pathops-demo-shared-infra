# pathops-demo-shared-infra

Bootstrap manifests for shared infrastructure in the PathOps demo environment.

## Local secrets

```bash
cp -r .secrets.example .secrets
chmod 700 .secrets
chmod 600 .secrets/*.env
git config core.hooksPath .githooks
```

## Components

- Keycloak
- PostgreSQL for Keycloak

## Current installation order

### 1. Prepare local secrets

```bash
cp -r .secrets.example .secrets
```

Edit:

```
.secrets/keycloak.env
.secrets/postgres.env
```

### 2. Install Keycloak and PostgreSQL

```bash
cd bootstrap/keycloak
./apply.sh
```

## Notes

- This repository is currently intended for manual bootstrap with kubectl.

- Plaintext credentials must not be committed to Git.