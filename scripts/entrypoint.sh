#!/bin/bash

set -e

INTERFACE=${INTERFACE:-awg0}
CONFIG_DIR="/etc/amnezia/amneziawg/config"
CONFIG_FILE="${CONFIG_DIR}/server.conf"
KEYS_FILE="${CONFIG_DIR}/server.keys"

echo "========================================"
echo "  AmneziaWG Server"
echo "========================================"
echo ""

# Create config directory if not exists
mkdir -p "$CONFIG_DIR"
mkdir -p "${CONFIG_DIR}/clients"

# Function to generate keys if they don't exist
generate_keys() {
    if [ ! -f "$KEYS_FILE" ]; then
        echo "Generating server keys..."
        PRIVATE_KEY=$(awg genkey)
        PUBLIC_KEY=$(printf "%s" "$PRIVATE_KEY" | awg pubkey)

        cat > "$KEYS_FILE" <<EOF
PRIVATE_KEY=${PRIVATE_KEY}
PUBLIC_KEY=${PUBLIC_KEY}
EOF
        chmod 600 "$KEYS_FILE"
        echo "✓ Keys generated and saved to $KEYS_FILE"
    else
        echo "✓ Using existing keys from $KEYS_FILE"
    fi
}

# Function to create server config if it doesn't exist
create_server_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Creating server configuration..."

        # Load keys
        source "$KEYS_FILE"

        # Calculate server VPN IP
        SERVER_VPN_IP=$(echo ${VPN_NETWORK} | sed 's/0\/24/1\/24/')

        cat > "$CONFIG_FILE" <<EOF
# AmneziaWG Server Configuration
# Auto-generated on $(date)

[Interface]
# Server's private key
PrivateKey = ${PRIVATE_KEY}

# Server's VPN IP address
Address = ${SERVER_VPN_IP}

# UDP port for AmneziaWG
ListenPort = ${LISTEN_PORT}

# AmneziaWG obfuscation parameters
# WARNING: These MUST match on ALL clients!
Jc = ${AWG_JC}
Jmin = ${AWG_JMIN}
Jmax = ${AWG_JMAX}
S1 = ${AWG_S1}
S2 = ${AWG_S2}
H1 = ${AWG_H1}
H2 = ${AWG_H2}
H3 = ${AWG_H3}
H4 = ${AWG_H4}

# NAT and routing
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${EXT_INTERFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${EXT_INTERFACE} -j MASQUERADE

# DNS for clients
DNS = ${DNS}


### Clients (Peers)
### Managed automatically - do not edit manually

EOF
        chmod 600 "$CONFIG_FILE"
        echo "✓ Server config created: $CONFIG_FILE"
    else
        echo "✓ Using existing config: $CONFIG_FILE"
    fi
}

# Initialize server
generate_keys
create_server_config

# Load keys for display
source "$KEYS_FILE"

echo ""
echo "Server Configuration:"
echo "  Interface: $INTERFACE"
echo "  Endpoint: ${SERVER_IP}:${LISTEN_PORT}"
echo "  VPN Network: ${VPN_NETWORK}"
echo "  Public Key: ${PUBLIC_KEY}"
echo "  Obfuscation: Jc=${AWG_JC}, Jmin=${AWG_JMIN}, Jmax=${AWG_JMAX}"
echo ""

# Set up IP forwarding (ignore errors in host network mode)
echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 2>/dev/null || echo "  (skipped - using host network)"
sysctl -w net.ipv6.conf.all.forwarding=1 2>/dev/null || echo "  (skipped - using host network)"

# Load kernel modules if not in container
if [ -d /lib/modules ]; then
    modprobe -q tun || true
    modprobe -q wireguard || true
fi

# Start AmneziaWG interface
echo "Starting interface $INTERFACE..."
awg-quick up "$CONFIG_FILE" || {
    echo "ERROR: Failed to start interface"
    exit 1
}

echo ""
echo "✓ AmneziaWG Server started successfully!"
echo ""
echo "Interface status:"
awg show 2>/dev/null || echo "  Interface is up (awg show not available yet)"
echo ""

# Keep container running and monitor interface
trap 'echo "Shutting down..."; awg-quick down "$CONFIG_FILE"; exit 0' SIGTERM SIGINT

# Log interface stats periodically
while true; do
    sleep 300  # 5 minutes
    if [ "$LOG_LEVEL" = "debug" ]; then
        echo "--- Interface Stats ---"
        awg show "$INTERFACE"
    fi
done
