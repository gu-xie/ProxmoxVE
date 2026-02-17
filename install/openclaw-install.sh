#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Gu (gu-xie)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openclaw.ai/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  ca-certificates \
  openssl
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs

msg_info "Installing Build Dependencies"
$STD apt-get install -y \
  build-essential \
  git
msg_ok "Installed Build Dependencies"

msg_info "Installing OpenClaw (Patience)"
$STD env SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install --global openclaw@latest
msg_ok "Installed OpenClaw"

msg_info "Creating Configuration"
mkdir -p /opt/openclaw
cat <<EOF >/opt/openclaw.env
OPENCLAW_HOME=/opt/openclaw
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
EOF
msg_ok "Created Configuration"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw Gateway Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/openclaw
EnvironmentFile=/opt/openclaw.env
ExecStart=/usr/bin/env openclaw gateway --bind lan --port 18789 --allow-unconfigured
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now openclaw
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
