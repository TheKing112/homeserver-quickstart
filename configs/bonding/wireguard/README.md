# WireGuard Configuration

## Server Setup

The server configuration is created automatically during quickstart installation.

Server public key is saved to: `/opt/homeserver/.wireguard-server-pubkey`

## Client Setup

### Generate Keys
```bash
# Private key
wg genkey > client_private.key

# Public key
wg pubkey < client_private.key > client_public.key
```

### Client Configuration

Create two tunnels on your PC (one for each connection):

**Tunnel 1 (e.g., Ethernet/Powerline):**
```ini
[Interface]
PrivateKey = <client1_private_key>
Address = 10.0.0.2/24

[Peer]
PublicKey = <server_public_key>
Endpoint = 192.168.1.100:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

**Tunnel 2 (e.g., WiFi):**
```ini
[Interface]
PrivateKey = <client2_private_key>
Address = 10.0.0.3/24

[Peer]
PublicKey = <server_public_key>
Endpoint = 192.168.1.100:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

### Add Clients to Server
```bash
sudo nano /etc/wireguard/wg0.conf

# Add:
[Peer]
PublicKey = <client1_public_key>
AllowedIPs = 10.0.0.2/32

[Peer]
PublicKey = <client2_public_key>
AllowedIPs = 10.0.0.3/32

# Restart
sudo systemctl restart wg-quick@wg0
```

### Verify
```bash
# On server
sudo wg show

# On client
ping 10.0.0.1
```

## Troubleshooting

**Connection fails:**
- Check firewall: `sudo ufw status`
- Verify keys are correct
- Check server is listening: `sudo ss -tulpn | grep 51820`

**No internet through tunnel:**
- Verify IP forwarding: `cat /proc/sys/net/ipv4/ip_forward`
- Check iptables rules
- Verify AllowedIPs setting