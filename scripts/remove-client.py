#!/usr/bin/env python3

import sys
import os
import shutil

def main():
    if len(sys.argv) != 2:
        print("Usage: remove-client.py <client-name>")
        sys.exit(1)

    client_name = sys.argv[1]
    config_dir = "./config"
    server_config = f"{config_dir}/server.conf"
    clients_dir = f"{config_dir}/clients"
    client_dir = f"{clients_dir}/{client_name}"

    # Check if client exists
    if not os.path.exists(client_dir):
        print(f"ERROR: Client '{client_name}' not found!")
        sys.exit(1)

    # Get client public key
    try:
        with open(f"{client_dir}/publickey", 'r') as f:
            client_public_key = f.read().strip()
    except FileNotFoundError:
        print(f"WARNING: Client public key not found, will try to remove by name only")
        client_public_key = None

    print(f"Removing client: {client_name}")
    if client_public_key:
        print(f"Public key: {client_public_key}")

    # Read server config
    with open(server_config, 'r') as f:
        lines = f.readlines()

    # Remove the [Peer] block containing this client
    new_lines = []
    i = 0
    removed = False

    while i < len(lines):
        line = lines[i]

        # Check if this is a [Peer] section
        if line.strip() == '[Peer]':
            # Look ahead to collect the entire peer block
            peer_block_lines = [line]
            j = i + 1

            # Collect the entire peer block until empty line or EOF or next [Peer]
            while j < len(lines):
                next_line = lines[j]
                if next_line.strip() == '' or next_line.strip().startswith('[Peer]'):
                    break
                peer_block_lines.append(next_line)
                j += 1

            # Check if this peer block contains our client
            peer_text = ''.join(peer_block_lines)
            should_remove = False

            # Check by client name comment
            if f"# Client: {client_name}" in peer_text:
                should_remove = True
            # Check by public key if available
            elif client_public_key and client_public_key in peer_text:
                should_remove = True

            if should_remove:
                # Skip this entire peer block
                removed = True
                i = j
                # Also skip the trailing empty line if present
                if i < len(lines) and lines[i].strip() == '':
                    i += 1
                continue
            else:
                # Keep this peer block
                new_lines.extend(peer_block_lines)
                i = j
                continue

        new_lines.append(line)
        i += 1

    if not removed:
        print(f"WARNING: Client '{client_name}' not found in server config")
    else:
        # Write back the config
        with open(server_config, 'w') as f:
            f.writelines(new_lines)
        print(f"✓ Removed client from server config")

    # Remove client directory
    try:
        shutil.rmtree(client_dir)
        print(f"✓ Removed client directory")
    except Exception as e:
        print(f"ERROR: Failed to remove client directory: {e}")
        sys.exit(1)

    print()
    print(f"✓ Client '{client_name}' removed successfully!")
    print()

if __name__ == "__main__":
    main()
