#!/bin/sh
set -e

echo "🔧 Initializing CLIProxyAPI with persistent storage..."

# Volume mount path
AUTH_DIR="${AUTH_DIR:-/data/.cli-proxy-api}"

# Create directories
mkdir -p "$AUTH_DIR"
mkdir -p /data/logs

# Verify volume
if mountpoint -q /data 2>/dev/null; then
    echo "✅ Volume mounted at /data"
else
    echo "⚠️  WARNING: /data is not a volume mount point!"
fi

# Check write permission
if [ -w "$AUTH_DIR" ]; then
    echo "✅ Auth directory is writable: $AUTH_DIR"
else
    echo "❌ ERROR: Cannot write to auth directory!"
    exit 1
fi

# Decode and restore OAuth tokens from ENV (if provided)
if [ -n "$CLAUDE_TOKEN_BASE64" ]; then
    echo "📝 Restoring Claude OAuth token..."
    echo "$CLAUDE_TOKEN_BASE64" | base64 -d > "$AUTH_DIR/claude.json"
fi

if [ -n "$GEMINI_TOKEN_BASE64" ]; then
    echo "📝 Restoring Gemini OAuth token..."
    echo "$GEMINI_TOKEN_BASE64" | base64 -d > "$AUTH_DIR/gemini.json"
fi

# ✅ Build API keys array from environment variables
API_KEYS=""
for i in 1 2 3 4 5 6 7 8 9 10; do
    KEY_VAR="CLIPROXY_API_KEY_$i"
    KEY_VALUE=$(eval echo \$$KEY_VAR)
    if [ -n "$KEY_VALUE" ]; then
        if [ -z "$API_KEYS" ]; then
            API_KEYS="    - \"$KEY_VALUE\""
        else
            API_KEYS="$API_KEYS\n    - \"$KEY_VALUE\""
        fi
        echo "✅ API Key $i loaded"
    fi
done

# If no API keys provided, leave empty (no auth required)
if [ -z "$API_KEYS" ]; then
    echo "⚠️  No API keys configured - authentication disabled!"
    API_KEYS_SECTION="  providers: []"
else
    API_KEYS_SECTION="  providers:\n$API_KEYS"
fi

# Generate config with API keys
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

auth:
$(echo -e "$API_KEYS_SECTION")

generative-language-api-key: []
EOF

echo "✅ Config generated with auth-dir: $AUTH_DIR"
echo ""
echo "📋 Generated config.yaml:"
echo "----------------------------------------"
cat /root/config.yaml
echo "----------------------------------------"

# List existing OAuth tokens
echo ""
echo "📁 Existing OAuth tokens:"
ls -lah "$AUTH_DIR" 2>/dev/null || echo "  (empty - will be created on first login)"

echo ""
echo "🚀 Starting CLIProxyAPI on port ${PORT:-8317}..."
exec ./cli-proxy-api --config /root/config.yaml "$@"
