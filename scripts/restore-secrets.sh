#!/usr/bin/env bash
set -euo pipefail

SOURCE_FILE="${1:-../pathops-demo-secrets/backups/shared-infra-secrets.tar.gz.gpg}"
TARGET_DIR="${2:-.secrets}"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "Encrypted backup not found: $SOURCE_FILE"
  exit 1
fi

mkdir -p "$TARGET_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

gpg --decrypt --output "$TMP_DIR/shared-infra-secrets.tar.gz" "$SOURCE_FILE"
tar -xzf "$TMP_DIR/shared-infra-secrets.tar.gz" -C "$TARGET_DIR"

chmod 700 "$TARGET_DIR" || true
chmod 600 "$TARGET_DIR"/* 2>/dev/null || true

echo "Secrets restored into:"
echo "  $TARGET_DIR"