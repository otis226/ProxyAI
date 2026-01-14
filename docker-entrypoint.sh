#!/bin/sh
set -e

echo "🔧 Initializing CLIProxyAPI..."

# ✅ Use volume path for persistent storage
AUTH_DIR="${AUTH_DIR:-/data/.cli-proxy-api}"

# Create auth directory in volume
mkdir -p "$AUTH_DIR"
echo "✅ Auth directory created: $AUTH_DIR"

# Check if volume is mounted properly
if [ -w "$AUTH_DIR" ]; then
    echo "✅ Volume is writable"
else
    echo "⚠️  Warning: Volume may not be mounted correctly"
fi

# Generate config file
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
  providers: []

generative-language-api-key: []
EOF

echo "✅ Config file generated:"
echo "----------------------------------------"
cat /root/config.yaml
echo "----------------------------------------"

# List existing auth files (if any)
if [ -d "$AUTH_DIR" ]; then
    echo ""
    echo "📁 Existing auth files:"
    ls -la "$AUTH_DIR" || echo "  (empty)"
fi

echo ""
echo "🚀 Starting CLIProxyAPI on port ${PORT:-8317}..."
exec ./cli-proxy-api --config /root/config.yaml "$@"
```

### **Bước 5: Set Environment Variable trên Railway:**
```
Settings → Variables → Add:

AUTH_DIR=/data/.cli-proxy-api

# Railway auto-injects volume path, nhưng tốt nhất là explicit
