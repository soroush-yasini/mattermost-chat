#!/usr/bin/env bash
# scripts/deploy.sh
# First-time deployment script for the Mattermost self-hosted stack.
# Run from the repository root directory.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

# ── 1. Verify .env exists ───────────────────────────────────────────────────
if [ ! -f ".env" ]; then
  echo "❌  .env file not found."
  echo "    Copy .env.example to .env and fill in your values first:"
  echo "    cp .env.example .env && nano .env"
  exit 1
fi

# Load DOMAIN from .env for the success message
# shellcheck disable=SC1091
DOMAIN=$(grep -E '^DOMAIN=' .env | cut -d= -f2 | tr -d '[:space:]"')
DOMAIN="${DOMAIN:-chat.company.internal}"

# ── 2. Generate TLS certificates ────────────────────────────────────────────
echo "==> Generating TLS certificates..."
bash "${SCRIPT_DIR}/gen-certs.sh" "$DOMAIN"

# ── 3. Ensure certs directory exists ────────────────────────────────────────
mkdir -p nginx/certs

# ── 4. Pull latest images ───────────────────────────────────────────────────
echo "==> Pulling Docker images..."
docker compose pull

# ── 5. Start the stack ──────────────────────────────────────────────────────
echo "==> Starting services..."
docker compose up -d

echo ""
echo "✅ Mattermost stack is up!"
echo "   Open https://${DOMAIN} in your browser."
echo "   (Make sure ${DOMAIN} resolves to this server's IP in your internal DNS.)"
