#!/bin/bash
# Standalone VS Code tunnel setup script
# Installs the VS Code CLI binary and sets up a systemd service for persistent tunneling.
# Usage: ./setup-vscode-tunnel.sh [tunnel-name]

set -e

if [ -n "$1" ]; then
    NODE_NAME="$1"
else
    read -e -p "Enter tunnel name [$(hostname)]: " NODE_NAME
    NODE_NAME="${NODE_NAME:-$(hostname)}"
fi

read -e -p "Enter root directory [$HOME]: " TUNNEL_DIR
TUNNEL_DIR="${TUNNEL_DIR:-$HOME}"
TUNNEL_DIR="$(realpath "$TUNNEL_DIR")"
if [ ! -d "$TUNNEL_DIR" ]; then
    echo "Error: $TUNNEL_DIR does not exist."
    exit 1
fi

VSCODE_CLI="$HOME/.local/bin/code"

# Install VS Code CLI binary
if [ ! -f "$VSCODE_CLI" ]; then
    echo "Installing VS Code CLI..."
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  VSCODE_ARCH="x64" ;;
        aarch64) VSCODE_ARCH="arm64" ;;
        *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    mkdir -p "$HOME/.local/bin"
    curl -fsSL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-${VSCODE_ARCH}" -o /tmp/vscode_cli.tar.gz
    tar -xzf /tmp/vscode_cli.tar.gz -C "$HOME/.local/bin"
    rm /tmp/vscode_cli.tar.gz
    echo "VS Code CLI installed to $VSCODE_CLI"
else
    echo "VS Code CLI already installed."
fi

# Authenticate (interactive - requires GitHub login)
echo ""
echo "=== Authenticating tunnel (name: $NODE_NAME) ==="
echo "Follow the URL below to authorize with GitHub."
echo ""
cd "$TUNNEL_DIR"
"$VSCODE_CLI" tunnel --name "$NODE_NAME" --accept-server-license-terms &
TUNNEL_PID=$!
echo ""
echo "Once authenticated, press Ctrl+C to stop the tunnel."
echo "The systemd service will keep it running permanently."
wait $TUNNEL_PID 2>/dev/null || true

# Set up systemd service
SERVICE_FILE="$HOME/.config/systemd/user/code.service"
if [ ! -f "$SERVICE_FILE" ]; then
    echo ""
    echo "Setting up systemd service..."
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=VS Code Tunnel ($NODE_NAME)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$TUNNEL_DIR
ExecStart=$HOME/.local/bin/code tunnel --name $NODE_NAME --accept-server-license-terms
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable code.service
    systemctl --user start code.service
    echo "VS Code tunnel service started and enabled on boot."
else
    echo "Service already exists. Restarting..."
    systemctl --user restart code.service
fi

echo ""
echo "Done! Connect via https://vscode.dev or VS Code Remote Tunnels extension."
echo "Tunnel name: $NODE_NAME"
echo ""
echo "Manage with:"
echo "  systemctl --user status code"
echo "  systemctl --user stop code"
echo "  systemctl --user start code"
