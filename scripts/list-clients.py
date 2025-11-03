#!/usr/bin/env python3

import os
import re

def main():
    config_dir = "./config"
    server_config = f"{config_dir}/server.conf"
    clients_dir = f"{config_dir}/clients"

    if not os.path.exists(server_config):
        print("ERROR: Server not initialized!")
        print("Please start the server first: docker-compose up -d")
        return

    if not os.path.exists(clients_dir):
        print("No clients found.")
        return

    # Get list of client directories
    try:
        client_names = [d for d in os.listdir(clients_dir)
                        if os.path.isdir(os.path.join(clients_dir, d))]
    except Exception as e:
        print(f"ERROR: Failed to list clients directory: {e}")
        return

    if not client_names:
        print("No clients found.")
        return

    print("=== AmneziaWG Clients ===")
    print()

    # Read server config once
    try:
        with open(server_config, 'r') as f:
            server_conf = f.read()
    except Exception as e:
        print(f"ERROR: Failed to read server config: {e}")
        return

    for client_name in sorted(client_names):
        client_dir = os.path.join(clients_dir, client_name)

        # Read client's public key
        pubkey_file = os.path.join(client_dir, "publickey")
        if os.path.exists(pubkey_file):
            try:
                with open(pubkey_file, 'r') as f:
                    public_key = f.read().strip()
            except Exception:
                public_key = "N/A"
        else:
            public_key = "N/A"

        # Find client's IP from server config
        client_ip = "N/A"

        # Try to find by client name comment first
        peer_pattern = rf'\[Peer\].*?# Client:\s*{re.escape(client_name)}.*?AllowedIPs\s*=\s*([0-9.]+)/32'
        match = re.search(peer_pattern, server_conf, re.DOTALL)

        if match:
            client_ip = match.group(1)
        elif public_key != "N/A":
            # Try to find by public key
            peer_pattern = rf'PublicKey\s*=\s*{re.escape(public_key)}.*?AllowedIPs\s*=\s*([0-9.]+)/32'
            match = re.search(peer_pattern, server_conf, re.DOTALL)
            if match:
                client_ip = match.group(1)

        print(f"Client: {client_name}")
        print(f"  IP: {client_ip}/32")
        print(f"  Public Key: {public_key[:20]}...{public_key[-10:]}" if len(public_key) > 30 else f"  Public Key: {public_key}")
        print()

if __name__ == "__main__":
    main()
