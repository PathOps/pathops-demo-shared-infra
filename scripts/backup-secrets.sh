#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="${1:-.secrets}"
TARGET_REPO="${2:-../pathops-demo-secrets}"
BACKUP_DIR="$TARGET_REPO/backups"
ARCHIVE_NAME="shared-infra-secrets.tar.gz"
ENCRYPTED_NAME="${ARCHIVE_NAME}.gpg"

if [ ! -d "$SRC_DIR" ]; then
  echo "Secrets directory not found: $SRC_DIR"
  exit 1
fi

if [ ! -d "$TARGET_REPO" ]; then
  echo "Target repo not found: $TARGET_REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

tar -czf "$TMP_DIR/$ARCHIVE_NAME" -C "$SRC_DIR" .

gpg --symmetric --cipher-algo AES256 \
  --output "$BACKUP_DIR/$ENCRYPTED_NAME" \
  "$TMP_DIR/$ARCHIVE_NAME"

echo "Encrypted backup created:"
echo "  $BACKUP_DIR/$ENCRYPTED_NAME"
echo
echo "Next steps:"
echo "  cd $TARGET_REPO"
echo "  git add $BACKUP_DIR/$ENCRYPTED_NAME"
echo "  git commit -m 'Update shared infra secrets backup'"