# Autoinstall Configuration

Enables fully automated Ubuntu Server installation.

## Usage

1. Download Ubuntu Server 24.04 LTS ISO
2. Create bootable USB with Rufus (Windows) or Etcher (Linux/Mac)
3. Copy this `autoinstall/` folder to USB root as `nocloud-ubuntu/`
4. Boot from USB
5. Installation runs automatically
6. Server reboots at 192.168.1.100

## Customization

### Network Settings

Edit `user-data`:
```yaml
network:
  ethernets:
    any:
      addresses: [192.168.1.100/24]  # Change IP
      routes:
        - to: default
          via: 192.168.1.1  # Change gateway
      nameservers:
        addresses: [192.168.1.1, 8.8.8.8]
```

### Hostname
```yaml
identity:
  hostname: homeserver  # Change here
```

### Password

Generate new password hash:
```bash
mkpasswd -m sha-512
```

Then replace in `password:` field.

### Additional Packages

Add to `packages:` list in `user-data`.

## Troubleshooting

**Installation fails?**
- Check BIOS/UEFI settings (disable Secure Boot)
- Verify USB creation was successful
- Check `autoinstall/` folder name on USB

**Network not working?**
- Verify network settings match your router
- Check cable connection
- Try DHCP instead of static IP

**Can't SSH after install?**
- Wait 2-3 minutes after reboot
- Verify IP address: `ip addr show`
- Check firewall: `sudo ufw status`

## What Gets Installed

- Ubuntu Server 24.04 LTS (minimal)
- Docker & Docker Compose
- WireGuard
- Essential tools (vim, git, htop, etc.)
- Firewall (UFW) pre-configured
- Fail2ban for security
- Automatic security updates

## Default Credentials

- **Username**: admin
- **Password**: homeserver (CHANGE IMMEDIATELY!)
- **SSH**: Enabled on port 22

## Next Steps

After successful installation:

1. SSH to server: `ssh admin@192.168.1.100`
2. Change password: `passwd`
3. Copy your `.env` file to `/opt/homeserver-setup/`
4. Run: `sudo /opt/homeserver-setup/scripts/01-quickstart.sh`