# AmneziaWG Server Docker Setup

Docker container for AmneziaWG server with traffic obfuscation support for bypassing DPI (Deep Packet Inspection).

## Features

- **Traffic Obfuscation** - Built-in DPI bypass using junk packets and header randomization
- **Docker-based** - Easy deployment and management
- **Client Management** - Scripts for adding/removing clients
- **NAT & Routing** - Automatic network configuration
- **Secure by default** - Uses PresharedKeys for additional security

## File Structure

```
.
├── docker-compose.yml           # Docker Compose configuration
├── Dockerfile                   # Build image from sources
├── server.conf.example          # Server configuration example
├── server.conf                  # Your server config (create from example)
├── clients/                     # Client configurations (auto-generated)
└── scripts/
    ├── entrypoint.sh           # Container startup script
    ├── add-client.sh           # Add new client
    ├── remove-client.sh        # Remove client
    ├── list-clients.sh         # List all clients
    └── show-client-qr.sh       # Show client QR code
```

## Quick Start

### 1. Initial Setup

Generate server keys and create configuration:

```bash
# Install amneziawg-tools (if not in Docker)
# Or use the client container to generate keys

# Generate server keys
docker run --rm -it alpine sh -c "apk add wget unzip && \
  cd /tmp && \
  wget https://github.com/amnezia-vpn/amneziawg-tools/releases/download/v1.0.20250901/alpine-3.19-amneziawg-tools.zip && \
  unzip -j alpine-3.19-amneziawg-tools.zip && \
  ./awg genkey"
```

Save the output (private key) and generate the public key:

```bash
echo 'YOUR_PRIVATE_KEY' | docker run --rm -i alpine sh -c "apk add wget unzip && \
  cd /tmp && \
  wget https://github.com/amnezia-vpn/amneziawg-tools/releases/download/v1.0.20250901/alpine-3.19-amneziawg-tools.zip && \
  unzip -j alpine-3.19-amneziawg-tools.zip && \
  ./awg pubkey"
```

### 2. Create Server Configuration

```bash
cp server.conf.example server.conf
nano server.conf
```

**Important**: Edit these fields:
- `PrivateKey` - Your server's private key (from step 1)
- `ListenPort` - UDP port (default: 51820)
- `Jc, Jmin, Jmax, S1, S2, H1-H4` - Obfuscation parameters (must match on all clients!)
- `PostUp/PostDown` - Change `eth0` to your external interface if needed

### 3. Configure Server Endpoint

Set your server's public IP for client configs:

```bash
export SERVER_ENDPOINT="YOUR_PUBLIC_IP:51820"
```

Or edit `scripts/add-client.sh` and change the default.

### 4. Build and Start Server

```bash
# Build the image
docker-compose build

# Start the server
docker-compose up -d

# Check logs
docker-compose logs -f
```

### 5. Add Your First Client

```bash
./scripts/add-client.sh laptop
```

This will:
- Generate client keys
- Create client config in `clients/laptop/laptop.conf`
- Add peer to server config
- Assign IP address automatically

**Important**: Restart server after adding clients:

```bash
docker-compose restart
```

### 6. Get Client Configuration

**Option A**: Copy config file
```bash
cat clients/laptop/laptop.conf
```

**Option B**: Show QR code (for mobile)
```bash
./scripts/show-client-qr.sh laptop
```

## Client Management

### Add New Client

```bash
./scripts/add-client.sh <client-name>
docker-compose restart
```

### Remove Client

```bash
./scripts/remove-client.sh <client-name>
docker-compose restart
```

### List All Clients

```bash
./scripts/list-clients.sh
```

### View Server Status

```bash
# Show all peers and traffic
docker exec amneziawg-server awg show

# Show specific interface
docker exec amneziawg-server awg show awg0
```

## Obfuscation Parameters Explained

AmneziaWG uses these parameters to disguise VPN traffic from DPI systems:

| Parameter | Description | Range | Recommended |
|-----------|-------------|-------|-------------|
| **Jc** | Number of junk packets before handshake | 1-128 | 3-10 |
| **Jmin** | Minimum junk packet size (bytes) | - | 50 |
| **Jmax** | Maximum junk packet size (bytes) | max 1280 | 1000 |
| **S1** | Garbage bytes in init handshake | - | 0 |
| **S2** | Garbage bytes in response handshake | - | 0 |
| **H1-H4** | Header randomization parameters | - | 1,2,3,4 |

**Important**:
- All clients MUST use the same parameters as the server!
- Higher values = better obfuscation but slightly more overhead
- Setting all to 0/default = regular WireGuard behavior

### Example Configurations

**Light obfuscation** (lower overhead):
```
Jc = 3
Jmin = 40
Jmax = 70
S1 = 10
S2 = 20
```

**Heavy obfuscation** (maximum stealth):
```
Jc = 10
Jmin = 50
Jmax = 1000
S1 = 50
S2 = 50
```

## Networking

### Port Forwarding

Make sure UDP port is accessible:

```bash
# Check if port is open
sudo ss -ulpn | grep 51820

# Open firewall (example for ufw)
sudo ufw allow 51820/udp
```

### Change Network Interface

If your external interface is not `eth0`, edit `server.conf`:

```bash
# Find your interface
ip route | grep default

# Update PostUp/PostDown rules
PostUp = iptables ... -o YOUR_INTERFACE ...
PostDown = iptables ... -o YOUR_INTERFACE ...
```

## Troubleshooting

### Server doesn't start

Check logs:
```bash
docker-compose logs
```

Common issues:
- Missing `server.conf` - create from example
- Invalid config syntax - check with `awg show`
- Port already in use - change `ListenPort`

### Clients can't connect

1. Verify obfuscation parameters match server:
```bash
grep -E "^(Jc|Jmin|Jmax|S1|S2|H1|H2|H3|H4)" server.conf
```

2. Check firewall:
```bash
sudo ss -ulpn | grep 51820
```

3. Verify server endpoint in client config is correct

### No internet on client

1. Check IP forwarding:
```bash
docker exec amneziawg-server sysctl net.ipv4.ip_forward
# Should return: net.ipv4.ip_forward = 1
```

2. Verify NAT rules:
```bash
docker exec amneziawg-server iptables -t nat -L POSTROUTING
```

3. Check `AllowedIPs` in client config:
```
AllowedIPs = 0.0.0.0/0, ::/0
```

## Advanced Configuration

### Enable Debug Logging

Edit `docker-compose.yml`:
```yaml
environment:
  - LOG_LEVEL=debug
```

Restart:
```bash
docker-compose restart
```

### Custom DNS

Add to `server.conf` under `[Interface]`:
```
DNS = 1.1.1.1, 8.8.8.8
```

### IPv6 Support

Add IPv6 address in `server.conf`:
```
Address = 10.8.0.1/24, fd00::1/64
```

And in client configs:
```
Address = 10.8.0.2/32, fd00::2/128
AllowedIPs = 0.0.0.0/0, ::/0
```

### Split Tunnel (route only specific traffic)

In client config, change `AllowedIPs`:
```
# Only route 10.0.0.0/8 through VPN
AllowedIPs = 10.0.0.0/8
```

## Security Notes

1. **Keep private keys secure** - Never share `server.conf` or `clients/*/privatekey`
2. **Use strong parameters** - Don't set all obfuscation to 0 in censored regions
3. **Regular updates** - Rebuild image periodically for security updates
4. **Firewall** - Only open necessary ports (51820/udp)
5. **PresharedKeys** - Always enabled for quantum-resistance

## Requirements

- Docker 20.10+
- Docker Compose 1.29+
- Linux kernel with TUN/TAP and WireGuard support
- Public IP address or port forwarding
- Open UDP port

## Updating

```bash
# Pull latest code
git pull

# Rebuild image
docker-compose build --no-cache

# Restart
docker-compose up -d
```

## Uninstall

```bash
# Stop and remove container
docker-compose down

# Remove image
docker rmi amneziawg-server

# Remove configs (CAREFUL!)
# rm -rf server.conf clients/
```

## References

- [AmneziaVPN Official](https://amnezia.org/)
- [amneziawg-go Repository](https://github.com/amnezia-vpn/amneziawg-go)
- [WireGuard Documentation](https://www.wireguard.com/)

## License

This project follows the licensing of amneziawg-go and WireGuard.
