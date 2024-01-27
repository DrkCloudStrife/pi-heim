#!/bin/bash

SERVER_DATA_FOLDER=${SERVER_DATA_FOLDER:-"valheim_data"}
SERVER_INSTALL_PATH=${SERVER_INSTALL_PATH:-"$HOME/valheim_server"}
SERVER_DATA_PATH="$HOME/${SERVER_DATA_FOLDER}"
SERVER_SCRIPT="start_server.sh"
BACKUPS="$HOME/backups"

mkdir -p "${BACKUPS}"

# Back up server script
cp "${SERVER_INSTALL_PATH}/${SERVER_SCRIPT}" "${HOME}/"

# Backup server data
if [ -d "${SERVER_DATA_PATH}" ]; then
  tar -zcf "${BACKUPS}/${SERVER_DATA_FOLDER}_$(date +%s).tar.gz" "${SERVER_DATA_PATH}"
fi

# Update server files
cd "${HOME}/steamcmd"
./steamcmd.sh +@sSteamCmdForcePlatformType linux +force_install_dir $SERVER_INSTALL_PATH +login anonymous +app_update 896660 validate +quit

# Restore server script
cp "${HOME}/${SERVER_SCRIPT}" "${SERVER_INSTALL_PATH}"
