#!/usr/bin/env bash

if [ -n "${SERVER_NAME}" ]; then
  # Assuming that if this is defined, this was already ran once before
  echo "\$SERVER_NAME is already configured, refusing to run"
  exit 0
fi

if [ -f "${HOME}/.env" ]; then
  # Adds script to load .env variables to .bashrc
  cat<<EOF >> "$HOME/.bashrc"
if [ -f "${HOME}/.env" ]; then
  export $(grep -v '^#' "${HOME}/.env" | xargs)
fi
EOF

  # First time running will not have the env variables
  export $(grep -v '^#' "${HOME}/.env" | xargs)
fi

# Fallback for if `.env` is not configured
SERVER_NAME=${SERVER_NAME:-"PiHeim"}

# Download steam
mkdir -p "${HOME}/steamcmd"
cd "${HOME}/steamcmd"
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
./steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +quit

cd $HOME

# Install/update Valheim Server
$HOME/update_server.sh

# Start Valheim Server
# tmux new-session -d -s "${SERVER_NAME}" $HOME/start_server.sh
