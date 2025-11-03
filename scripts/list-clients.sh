#!/bin/bash

CONFIG_DIR="./config"
CLIENTS_DIR="${CONFIG_DIR}/clients"

echo "AmneziaWG Server - Client List"
echo "================================"
echo ""

if [ ! -d "$CLIENTS_DIR" ] || [ -z "$(ls -A "$CLIENTS_DIR" 2>/dev/null)" ]; then
    echo "No clients found."
    exit 0
fi

for client_dir in "$CLIENTS_DIR"/*; do
    if [ -d "$client_dir" ]; then
        CLIENT_NAME=$(basename "$client_dir")
        CLIENT_CONFIG="${client_dir}/${CLIENT_NAME}.conf"

        if [ -f "$CLIENT_CONFIG" ]; then
            CLIENT_IP=$(grep '^Address' "$CLIENT_CONFIG" | awk '{print $3}')
            CLIENT_PUBKEY=$(cat "${client_dir}/publickey" 2>/dev/null || echo "N/A")

            echo "Client: $CLIENT_NAME"
            echo "  IP: $CLIENT_IP"
            echo "  Public Key: ${CLIENT_PUBKEY:0:32}..."
            echo ""
        fi
    fi
done
