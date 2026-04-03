# Linux Setup Guide

This guide covers running Heisenberg Team on Ubuntu/Debian Linux (VPS or local).

## Prerequisites

- Ubuntu 20.04+ / Debian 11+
- Node.js 18+ (`curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -`)
- OpenClaw (`npm install -g openclaw`)
- Git, jq, curl

## Differences from macOS

### Gateway as systemd service

Instead of macOS LaunchAgents, use systemd:

```bash
# Create service file
sudo tee /etc/systemd/system/openclaw-gateway.service > /dev/null << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/openclaw gateway start --foreground
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable openclaw-gateway
sudo systemctl start openclaw-gateway

# Check status
sudo systemctl status openclaw-gateway
```

### User-level systemd (recommended for non-root)

```bash
mkdir -p ~/.config/systemd/user/

cat > ~/.config/systemd/user/openclaw-gateway.service << 'EOF'
[Unit]
Description=OpenClaw Gateway

[Service]
Type=simple
ExecStart=%h/.npm-global/bin/openclaw gateway start --foreground
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable openclaw-gateway
systemctl --user start openclaw-gateway
```

### stat command differences

All scripts in `scripts/` auto-detect the platform and use the correct `stat` syntax. No manual changes needed.

### Process management

- macOS: `launchctl kickstart -k ...`
- Linux: `systemctl restart openclaw-gateway` or `openclaw gateway restart`

All scripts auto-detect and use the correct command.

## Firewall

```bash
# Allow only local access to gateway (recommended)
sudo ufw allow from 127.0.0.1 to any port 3120
sudo ufw deny 3120
```

## Installation

```bash
# 1. Install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Install OpenClaw
npm install -g openclaw

# 3. Clone and setup
git clone https://github.com/YOUR_USERNAME/heisenberg-team.git
cd heisenberg-team
cp .env.example .env
# Edit .env with your values

# 4. Run setup wizard
bash scripts/setup-wizard.sh

# 5. Start gateway
openclaw gateway start
```

## Troubleshooting

### Gateway won't start

```bash
# Check logs
journalctl --user -u openclaw-gateway -f

# Or for system service
sudo journalctl -u openclaw-gateway -f
```

### Permission errors

```bash
# Fix npm global permissions
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Port already in use

```bash
# Find what's using the port
sudo lsof -i :18789

# Kill the process
sudo kill -9 <PID>
```

### Memory issues on VPS

For low-memory VPS (1-2GB RAM), consider:

```bash
# Add swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## Cron Setup

Linux uses systemd timers or traditional cron. The setup wizard handles this automatically.

Manual cron setup:

```bash
# Edit crontab
crontab -e

# Add entries (example)
*/30 * * * * cd ~/heisenberg-team && bash scripts/self-heal.sh >> ~/.openclaw/logs/self-heal.log 2>&1
0 3 * * * cd ~/heisenberg-team && bash scripts/night-cleanup.sh >> ~/.openclaw/logs/night-cleanup.log 2>&1
```

## Docker Support

If you prefer Docker:

```bash
# Build
docker build -t heisenberg-team .

# Run
docker run -d \
  --name heisenberg \
  -p 18789:18789 \
  -v ~/.openclaw:/root/.openclaw \
  heisenberg-team
```

## Support

- [Main README](../README.md)
- [SETUP.md](../SETUP.md)
- [FAQ](faq.md)
