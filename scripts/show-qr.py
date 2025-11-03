#!/usr/bin/env python3

import sys
import os
import subprocess

def main():
    if len(sys.argv) != 2:
        print("Usage: show-qr.py <client-name>")
        sys.exit(1)

    client_name = sys.argv[1]
    config_dir = "./config"
    clients_dir = f"{config_dir}/clients"
    client_config = f"{clients_dir}/{client_name}/{client_name}.conf"

    # Check if client exists
    if not os.path.exists(client_config):
        print(f"ERROR: Client '{client_name}' not found!")
        print(f"Config file does not exist: {client_config}")
        sys.exit(1)

    # Read config
    try:
        with open(client_config, 'r') as f:
            config_content = f.read()
    except Exception as e:
        print(f"ERROR: Failed to read config: {e}")
        sys.exit(1)

    print(f"=== QR Code for client: {client_name} ===")
    print()

    # Use Python qrcode library
    try:
        import qrcode

        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=1,
            border=1,
        )
        qr.add_data(config_content)
        qr.make(fit=True)

        # Print to terminal with ASCII
        qr.print_ascii(invert=True)
        print()
        print("Scan this QR code with AmneziaWG mobile app")
        print()
        return
    except ImportError:
        print("ERROR: Python qrcode library not found!")
        print()
        print("Please install it:")
        print("  pip3 install qrcode")
        print()
        print(f"Or manually show the config file:")
        print(f"  cat {client_config}")
        sys.exit(1)
    except Exception as e:
        print(f"ERROR: Failed to generate QR code: {e}")
        print()
        print(f"You can manually show the config file:")
        print(f"  cat {client_config}")
        sys.exit(1)

if __name__ == "__main__":
    main()
