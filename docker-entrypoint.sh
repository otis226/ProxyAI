#!/bin/sh
set -e

echo "🔧 Initializing CLIProxyAPI..."

# Create auth directory
mkdir -p /root/.cli-proxy-api
echo "✅ Auth directory created: /root/.cli-proxy-api"

# Generate config file
cat > /root/config.yaml <<EOF
port: ${PORT:-8317}

remote-management:
  allow-remote: ${ALLOW_REMOTE:-true}
  secret-key: "${RAILWAY_MANAGEMENT_KEY:-}"
  disable-control-panel: false

auth-dir: "/root/.cli-proxy-api"

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

echo ""
echo "🚀 Starting CLIProxyAPI on port ${PORT:-8317}..."
exec ./cli-proxy-api --config /root/config.yaml "$@"
