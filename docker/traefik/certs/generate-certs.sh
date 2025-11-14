#!/bin/bash

# ========================================
# GENERATE SELF-SIGNED CERTIFICATES
# ========================================
# For development use only
# DO NOT use in production - use Let's Encrypt instead
# ========================================

set -e

CERT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOMAIN="${1:-localhost}"
DAYS="${2:-365}"

echo "========================================="
echo "Generating Self-Signed Certificates"
echo "========================================="
echo "Domain: $DOMAIN"
echo "Validity: $DAYS days"
echo "Directory: $CERT_DIR"
echo "========================================="

# Create directory if it doesn't exist
mkdir -p "$CERT_DIR"

# Generate CA private key
echo "[1/6] Generating CA private key..."
openssl genrsa -out "$CERT_DIR/ca.key" 4096

# Generate CA certificate
echo "[2/6] Generating CA certificate..."
openssl req -x509 -new -nodes \
  -key "$CERT_DIR/ca.key" \
  -sha256 \
  -days "$DAYS" \
  -out "$CERT_DIR/ca.crt" \
  -subj "/C=FR/ST=IDF/L=Paris/O=Entrance Cockpit/OU=IT/CN=Entrance Cockpit CA"

# Generate server private key
echo "[3/6] Generating server private key..."
openssl genrsa -out "$CERT_DIR/$DOMAIN.key" 2048

# Generate certificate signing request (CSR)
echo "[4/6] Generating CSR..."
openssl req -new \
  -key "$CERT_DIR/$DOMAIN.key" \
  -out "$CERT_DIR/$DOMAIN.csr" \
  -subj "/C=FR/ST=IDF/L=Paris/O=Entrance Cockpit/OU=IT/CN=$DOMAIN"

# Create extensions file for SAN
echo "[5/6] Creating SAN configuration..."
cat > "$CERT_DIR/$DOMAIN.ext" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
DNS.3 = localhost
DNS.4 = *.localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# Generate server certificate signed by CA
echo "[6/6] Generating server certificate..."
openssl x509 -req \
  -in "$CERT_DIR/$DOMAIN.csr" \
  -CA "$CERT_DIR/ca.crt" \
  -CAkey "$CERT_DIR/ca.key" \
  -CAcreateserial \
  -out "$CERT_DIR/$DOMAIN.crt" \
  -days "$DAYS" \
  -sha256 \
  -extfile "$CERT_DIR/$DOMAIN.ext"

# Clean up temporary files
rm -f "$CERT_DIR/$DOMAIN.csr" "$CERT_DIR/$DOMAIN.ext" "$CERT_DIR/ca.srl"

# Set proper permissions
chmod 600 "$CERT_DIR"/*.key
chmod 644 "$CERT_DIR"/*.crt

echo ""
echo "========================================="
echo "✓ Certificates generated successfully!"
echo "========================================="
echo ""
echo "Generated files:"
echo "  - CA Certificate:     $CERT_DIR/ca.crt"
echo "  - CA Private Key:     $CERT_DIR/ca.key"
echo "  - Server Certificate: $CERT_DIR/$DOMAIN.crt"
echo "  - Server Private Key: $CERT_DIR/$DOMAIN.key"
echo ""
echo "To trust the CA certificate:"
echo "  Linux:   sudo cp $CERT_DIR/ca.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates"
echo "  macOS:   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $CERT_DIR/ca.crt"
echo "  Windows: Import $CERT_DIR/ca.crt to 'Trusted Root Certification Authorities'"
echo ""
echo "Browser specific:"
echo "  Chrome:  chrome://settings/certificates -> Authorities -> Import"
echo "  Firefox: about:preferences#privacy -> Certificates -> View Certificates -> Authorities -> Import"
echo ""
echo "========================================="
