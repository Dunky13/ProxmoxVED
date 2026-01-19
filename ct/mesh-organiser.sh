#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/Dunky13/ProxmoxVED/refs/heads/feature/mesh-organizer/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Dunky13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/suchmememanyskill/mesh-organiser

APP="mesh-organiser"
var_tags="${var_tags:-sharing}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors
function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/mesh-organiser ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "mesh-organiser" "suchmememanyskill/mesh-organiser"; then
    # NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs
    setup_rust

    msg_info "Stopping Service"
    systemctl stop mesh-organiser
    msg_ok "Stopped Service"

    # mkdir -p /opt/mesh-organiser-backup
    # cp /opt/mesh-organiser/.env /opt/mesh-organiser-backup/.env
    # cp -a /opt/mesh-organiser/uploads /opt/mesh-organiser-backup
    # cp -a /opt/mesh-organiser/data /opt/mesh-organiser-backup

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "mesh-organiser" "suchmememanyskill/mesh-organiser" "tarball"

    msg_info "Updating mesh-organiser"
    cd /opt/mesh-organiser
    chmod +x ./build-web.sh
    export TARGETPLATFORM="linux/$(dpkg --print-architecture)"
    $STD ./build-web.sh
    msg_ok "Updated mesh-organiser"
    msg_info "Starting Service"
    systemctl start mesh-organiser
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3280${CL}"
