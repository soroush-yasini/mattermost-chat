#!/usr/bin/env bash
# scripts/gen-certs.sh
# Generate a self-signed internal CA and a server TLS certificate.
# Usage: ./scripts/gen-certs.sh [domain]
# Outputs to ./nginx/certs/

set -e

DOMAIN="${1:-chat.company.internal}"
CERTS_DIR="$(dirname "$0")/../nginx/certs"

mkdir -p "$CERTS_DIR"
cd "$CERTS_DIR"

echo "==> Generating certificates for domain: ${DOMAIN}"
echo "    Output directory: $(pwd)"

# ── 1. Internal CA ──────────────────────────────────────────────────────────
echo "==> [1/3] Creating internal CA (4096-bit)..."
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 3650 \
  -key ca.key \
  -out ca.crt \
  -subj "/C=XX/ST=Internal/L=Intranet/O=CompanyCA/CN=CompanyInternalCA"

# ── 2. Server key & CSR ─────────────────────────────────────────────────────
echo "==> [2/3] Creating server key (2048-bit) and CSR..."
openssl genrsa -out server.key 2048
openssl req -new \
  -key server.key \
  -out server.csr \
  -subj "/C=XX/ST=Internal/L=Intranet/O=Company/CN=${DOMAIN}"

# ── 3. Sign the server cert with the CA ─────────────────────────────────────
echo "==> [3/3] Signing server certificate (valid 3650 days)..."
cat > server.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName=@alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = localhost
IP.1  = 127.0.0.1
EOF

openssl x509 -req -days 3650 \
  -in server.csr \
  -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out server.crt \
  -extfile server.ext

echo ""
echo "✅ Certificates generated successfully in: $(pwd)"
echo ""
echo "────────────────────────────────────────────────────────────────"
echo " How to install ca.crt on Android (for Mattermost Android app)"
echo "────────────────────────────────────────────────────────────────"
echo " 1. Copy ca.crt to your Android device (e.g. via USB or email)."
echo " 2. On Android: Settings → Security → Install a certificate"
echo "    → CA certificate → select ca.crt."
echo " 3. In the Mattermost app: tap 'Enter Server URL' and enter:"
echo "    https://${DOMAIN}"
echo " 4. Accept the connection — Android will trust your internal CA."
echo "────────────────────────────────────────────────────────────────"
