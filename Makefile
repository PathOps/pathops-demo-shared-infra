export-chatgpt:
	./scripts/export_repo_dump.sh

backup-secrets:
	./scripts/backup-secrets.sh

restore-secrets:
	./scripts/restore-secrets.sh

vault-unseal:
	./scripts/vault-unseal.sh

vault-login:
	./scripts/vault-login.sh