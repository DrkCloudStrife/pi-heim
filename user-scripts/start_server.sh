#!/bin/bash
export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$HOME/valheim_server/linux64:$LD_LIBRARY_PATH
export SteamAppId=892970

echo "Starting server PRESS CTRL-C to exit"

SERVER_DATA_PATH=${SERVER_DATA_PATH:-"${HOME}/valheim_data"}
SERVER_NAME=${SERVER_NAME:-"PiHeim"}
SERVER_PASSWORD=${SERVER_PASSWORD:-"CHANGEME"}
SERVER_PUBLIC=${SERVER_PUBLIC:-0}
SERVER_PORT=${SERVER_PORT:-2456}
WORLD_NAME=${WORLD_NAME:-"PiWorld"}

# ADVANCED_SETTINGS="-modifier resources more -modifier portals casual -modifier raids muchless -setkey nomap"
ADVANCED_SETTINGS=${ADVANCED_SETTINGS:-""}

# Tip: Make a local copy of this script to avoid it being overwritten by steam.
# NOTE: Minimum password length is 5 characters & Password cant be in the server name.
# NOTE: You need to make sure the ports 2456-2458 is being forwarded to your server through your local router & firewall.
$HOME/valheim_server/valheim_server.x86_64 \
	-name "${SERVER_NAME}" -port $SERVER_PORT -world "${WORLD_NAME}" -password "${SERVER_PASSWORD}" \
  -savedir $SERVER_DATA_PATH -nographics -batchmode -public $SERVER_PUBLIC $ADVANCED_SETTINGS

export LD_LIBRARY_PATH=$templdpath
