#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Dunky13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/suchmememanyskill/mesh-organiser

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt install -y \
  build-essential \
  python3 \
  openssl \
  caddy
msg_ok "Installed dependencies"

# NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs
setup_rust
fetch_and_deploy_gh_release "mesh-organiser" "suchmememanyskill/mesh-organiser" "tarball"
import_local_ip

msg_info "Installing mesh-organiser"
cd /opt/mesh-organiser
chmod +x ./build-web.sh
export TARGETPLATFORM="linux/$(dpkg --print-architecture)"
$STD ./build-web.sh
msg_ok "Installed mesh-organiser"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/mesh-organiser.service
[Unit]
Description=mesh-organiser Service
After=network.target

[Service]
WorkingDirectory=/opt/mesh-organiser
EnvironmentFile=/opt/mesh-organiser/.env
ExecStart=/usr/bin/env sh -c './entrypoint.sh'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mesh-organiser
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
