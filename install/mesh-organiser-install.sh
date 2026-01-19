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
  wget \
  xz-utils \
  nodejs \
  libfontconfig1-dev \
  libssl-dev \
  openssl \
  build-essential \
  cmake \
  gcc-aarch64-linux-gnu \
  g++-aarch64-linux-gnu
msg_ok "Installed dependencies"

NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs
setup_rust
fetch_and_deploy_gh_release "mesh-organiser" "suchmememanyskill/mesh-organiser" "tarball"
import_local_ip

msg_info "Installing mesh-organiser"
cd /opt/mesh-organiser
chmod +x ./build-web.sh

# Patch build-web.sh to stop using hardcoded /source paths (Docker-only)
# Original script copies:
#   /source/web/target/$RUST_TARGET/release/web -> /source/web/target/release/web
# We want it to use /opt/mesh-organiser instead.
sed -i 's#/source#/opt/mesh-organiser#g' ./build-web.sh

export TARGETPLATFORM="linux/$(dpkg --print-architecture)"

$STD ./build-web.sh

$STD pnpm install --frozen-lockfile || $STD pnpm install
export VITE_API_PLATFORM="web"
$STD pnpm build

install -d /opt/mesh-organiser/runtime
install -m 0755 /opt/mesh-organiser/web/target/release/web \
  /opt/mesh-organiser/runtime/web

rm -rf /opt/mesh-organiser/runtime/www
cp -a /opt/mesh-organiser/build /opt/mesh-organiser/runtime/www

msg_ok "Installed mesh-organiser"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/mesh-organiser.service
[Unit]
Description=mesh-organiser Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/mesh-organiser/runtime
EnvironmentFile=-/opt/mesh-organiser/.env
ExecStart=/opt/mesh-organiser/runtime/web
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mesh-organiser
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
