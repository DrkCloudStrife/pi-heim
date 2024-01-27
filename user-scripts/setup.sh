#!/usr/bin/env bash

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

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
tmux new-session -d -s "${SERVER_NAME}" $HOME/start_server.sh
