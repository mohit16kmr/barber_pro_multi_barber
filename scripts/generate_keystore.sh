#!/usr/bin/env bash
# Usage: ./scripts/generate_keystore.sh <keystore-name.jks> <alias> <store-pass> <key-pass>
# Example: ./scripts/generate_keystore.sh release.jks upload storepass keypass

set -euo pipefail
if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <keystore-file> <alias> <store-password> <key-password>"
  exit 2
fi

KEYSTORE_FILE="$1"
ALIAS="$2"
STORE_PASS="$3"
KEY_PASS="$4"

# Generate keystore
keytool -genkeypair \
  -v -keystore "$KEYSTORE_FILE" \
  -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias "$ALIAS" \
  -storepass "$STORE_PASS" \
  -keypass "$KEY_PASS" \
  -dname "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, S=Unknown, C=US"

# Output key.properties content
cat > android/key.properties <<EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=$ALIAS
storeFile=$KEYSTORE_FILE
EOF

# Print base64 (use this value as secrets.ANDROID_KEYSTORE)
echo "--- Base64 of keystore (copy into GitHub secret ANDROID_KEYSTORE) ---"
base64 "$KEYSTORE_FILE"

echo "Created $KEYSTORE_FILE and android/key.properties"
