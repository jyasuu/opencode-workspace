#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="/usr/local/bin"

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Detect ARCH
case "$(uname -m)" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
esac

echo "OS   : $OS"
echo "ARCH : $ARCH"

########################################
# Install NATS CLI
########################################

echo
echo "Fetching latest NATS CLI release..."

CLI_ASSET_URL=$(
    curl -fsSL https://api.github.com/repos/nats-io/natscli/releases/latest |
    grep browser_download_url |
    grep "${OS}-${ARCH}.zip" |
    cut -d '"' -f 4 |
    head -n1
)

if [ -z "$CLI_ASSET_URL" ]; then
    echo "Unable to locate NATS CLI asset"
    exit 1
fi

echo "Downloading:"
echo "$CLI_ASSET_URL"

rm -rf /tmp/natscli
mkdir -p /tmp/natscli

curl -fL "$CLI_ASSET_URL" -o /tmp/natscli.zip
unzip -q /tmp/natscli.zip -d /tmp/natscli

CLI_BIN=$(find /tmp/natscli -type f -name nats | head -n1)

sudo install -m 755 "$CLI_BIN" "$INSTALL_DIR/nats"

########################################
# Install NATS Server
########################################

echo
echo "Fetching latest NATS Server release..."

SERVER_VERSION=$(
    curl -fsSL https://api.github.com/repos/nats-io/nats-server/releases/latest |
    grep '"tag_name"' |
    cut -d '"' -f 4
)

SERVER_URL="https://github.com/nats-io/nats-server/releases/download/${SERVER_VERSION}/nats-server-${SERVER_VERSION}-${OS}-${ARCH}.tar.gz"

echo "Downloading:"
echo "$SERVER_URL"

curl -fL "$SERVER_URL" -o /tmp/nats-server.tgz

rm -rf /tmp/nats-server
mkdir -p /tmp/nats-server

tar -xzf /tmp/nats-server.tgz -C /tmp/nats-server

SERVER_BIN=$(find /tmp/nats-server -type f -name nats-server | head -n1)

sudo install -m 755 "$SERVER_BIN" "$INSTALL_DIR/nats-server"

########################################
# Verify
########################################

echo
echo "Verification"

which nats
which nats-server

echo
nats --version

echo
nats-server --version

echo
echo "Installation complete."