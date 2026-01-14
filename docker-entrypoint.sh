#!/bin/sh
set -e

echo "🔧 Initializing CLIProxyAPI..."

AUTH_DIR="${AUTH_DIR:-/data/.cli-proxy-api}"
mkdir -p "$AUTH_DIR"

# Verify volume
if mountpoint -q /data 2>/dev/null; then
    echo "✅ Volume mounted at /data"
fi

# ==========================================
# Load API Keys from ENV (_1, _2, _3...)
# ==========================================
echo "📝 Loading API keys from environment variables..."

API_KEYS_SECTION=""
ENV_KEY_COUNT=0

# Loop through _1 to _50 (adjust limit as needed)
for i in $(seq 1 50); do
    KEY_VAR="CLIPROXY_API_KEY_$i"
    KEY_VALUE=$(eval echo \$$KEY_VAR)
    
    if [ -n "$KEY_VALUE" ]; then
        API_KEYS_SECTION="${API_KEYS_SECTION}  - \"${KEY_VALUE}\"\n"
        ENV_KEY_COUNT=$((ENV_KEY_COUNT + 1))
        echo "  ✓ Key $i loaded"
    fi
done

echo "✅ Loaded $ENV_KEY_COUNT API keys from ENV"

# ==========================================
# Load from Volume File (optional)
# ==========================================
API_KEYS_FILE="$AUTH_DIR/api-keys.txt"
FILE_KEY_COUNT=0

if [ -f "$API_KEYS_FILE" ]; then
    echo "📝 Loading API keys from file..."
    
    while IFS= read -r key; do
        key=$(echo "$key" | xargs)  # trim whitespace
        # Skip empty lines and comments
        if [ -n "$key" ] && [ "${key#\#}" = "$key" ]; then
            API_KEYS_SECTION="${API_KEYS_SECTION}  - \"${key}\"\n"
            FILE_KEY_COUNT=$((FILE_KEY_COUNT + 1))
        fi
    done < "$API_KEYS_FILE"
    
    echo "✅ Loaded $FILE_KEY_COUNT API keys from file"
fi

# ==========================================
# Calculate Total
# ==========================================
TOTAL_KEYS=$((ENV_KEY_COUNT + FILE_KEY_COUNT))

if [ $TOTAL_KEYS -eq 0 ]; then
    echo ""
    echo "⚠️  WARNING: No API keys configured!"
    echo "   Authentication is DISABLED - anyone can access!"
    echo "   Set CLIPROXY_API_KEY_1, CLIPROXY_API_KEY_2, etc."
    API_KEYS_SECTION="  []"
else
    echo ""
    echo "✅ Total API keys configured: $TOTAL_KEYS"
fi

# ==========================================
# Generate Config
# ==========================================
cat > /root/config.yaml <<EOF
port: ${PORT:-8317}

remote-management:
  allow-remote: ${ALLOW_REMOTE:-true}
  secret-key: "${RAILWAY_MANAGEMENT_KEY:-}"
  disable-control-panel: false

auth-dir: "$AUTH_DIR"

debug: ${DEBUG:-false}
logging-to-file: true
usage-statistics-enabled: true

proxy-url: "${PROXY_URL:-}"
request-retry: ${REQUEST_RETRY:-3}

quota-exceeded:
  switch-project: true
  switch-preview-model: true

api-keys:
$(echo -e "$API_KEYS_SECTION")

generative-language-api-key: []
EOF

echo ""
echo "📋 Config preview (keys masked):"
echo "----------------------------------------"
sed 's/- ".*"/- "************************"/' /root/config.yaml | head -35
echo "----------------------------------------"

# List OAuth tokens
if [ -d "$AUTH_DIR" ] && [ "$(ls -A $AUTH_DIR 2>/dev/null)" ]; then
    echo ""
    echo "📁 OAuth tokens in volume:"
    ls -lh "$AUTH_DIR" | grep -v "api-keys.txt" | tail -n +2 || echo "  (none)"
fi

echo ""
echo "🚀 Starting CLIProxyAPI on port ${PORT:-8317}..."
exec ./cli-proxy-api --config /root/config.yaml "$@"
