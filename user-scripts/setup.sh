#!/usr/bin/env bash

# Assuming that if this is defined, this was already ran once before
if grep -q "source.*export)" $HOME/.bashrc; then
  echo "Server is already configured, refusing to run"
  echo "  To start the server, run \`systemctl --user start valheim\`"
  exit 0
fi

if [ -f "${HOME}/.env" ]; then
  # Adds script to load .env variables to .bashrc
  cat<<EOF >> "$HOME/.bashrc"
if [ -f "\${HOME}/.env" ]; then
  source <(sed -E -n 's/[^#]+/export &/p' \$HOME/.env)
fi
EOF

  # First time running will not have the env variables
  source <(sed -E -n 's/[^#]+/export &/p' $HOME/.env)
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
echo "Do you want to start the server?"
select yn in "Yes" "No"; do
  case $yn in
    Yes ) XDG_RUNTIME_DIR="/run/user/$UID" DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus" systemctl --user start valheim; break;;
    No ) exit;;
  esac
done
