#!/bin/bash

set -e

CONFIG_DIR="./config"
SERVER_CONFIG="${CONFIG_DIR}/server.conf"
CLIENTS_DIR="${CONFIG_DIR}/clients"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -ne 1 ]; then
    echo -e "${RED}Usage: $0 <client-name>${NC}"
    echo "Example: $0 laptop"
    exit 1
fi

CLIENT_NAME="$1"
CLIENT_DIR="${CLIENTS_DIR}/${CLIENT_NAME}"

if [ ! -d "$CLIENT_DIR" ]; then
    echo -e "${RED}ERROR: Client '$CLIENT_NAME' not found!${NC}"
    exit 1
fi

# Get client public key
CLIENT_PUBLIC_KEY=$(cat "${CLIENT_DIR}/publickey")

echo -e "${YELLOW}Removing client: ${CLIENT_NAME}${NC}"
echo "Public key: ${CLIENT_PUBLIC_KEY}"

# Remove client section from server config
sed -i "/# Client: ${CLIENT_NAME}/,/^$/d" "$SERVER_CONFIG" 2>/dev/null || true
sed -i "/PublicKey = ${CLIENT_PUBLIC_KEY}/,/^$/d" "$SERVER_CONFIG" 2>/dev/null || true

# Remove client directory
rm -rf "$CLIENT_DIR"

echo -e "${GREEN}✓ Client '${CLIENT_NAME}' removed successfully!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "Restart the server: docker-compose restart"
echo ""
