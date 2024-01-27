#!/usr/bin/env bash

set -euo pipefail
IFS=$' \n\t'

magenta() { echo $'\e[1;35m'$1$'\e[0m'; }
red() { echo $'\e[1;31m'$1$'\e[0m'; }
green() { echo $'\e[1;32m'$1$'\e[0m'; }
yellow() { echo $'\e[1;33m'$1$'\e[0m'; }

generage_pw() { echo $(date +%s%N) | sha256sum | head -c 8; }

command_exists() { type "$1" &> /dev/null ; }

# Config
########

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

CLIENT_USERNAME=${CLIENT_USERNAME:-"steam"}
CLIENT_PASSWORD=${CLIENT_PASSWORD:-"steampw"}
SERVER_NAME=${SERVER_NAME:-"PiHeim"}
SERVER_PASSWORD=${SERVER_PASSWORD:-"$(generage_pw)"}
SERVER_PORT=${SERVER_PORT:-"2456"}
SERVER_PUBLIC=${SERVER_PUBLIC:-"0"}
SERVER_INSTALL_PATH=${SERVER_INSTALL_PATH:-"$HOME/valheim_server"}
SERVER_DATA_PATH=${SERVER_DATA_PATH:-"$HOME/valheim_data"}

# Validate
##########

# Exit if machine is not Linux aarch64
if [[ "$(uname -s)" != "Linux" && "$(arch)" != "aarch64" ]]; then
  red "Ensure this is ran on the Raspberry Pi with aarch64 OS (64-bit)"
  exit 1
fi

# Exit if PageSize is greater than 4k
if [[ "$(getconf PAGESIZE)" -gt 4096 ]]; then
  red "Box86 cannot run on a system with PageSize greater than 4k\nSee https://github.com/ptitSeb/box86/issues/912"
  exit 1
fi

# Ensure prerequisites are installed
magenta "You will be asked for your password to update upgrade, and install 'apt' dependencies."

sudo dpkg --add-architecture armhf
sudo apt update
sudo apt full-upgrade -y
sudo apt install -y tmux vim
sudo apt install -y git build-essential cmake
sudo apt install -y gcc-arm-linux-gnueabihf libc6:armhf libstdc++6:armhf libncurses5:armhf libncurses6:armhf
sudo apt install -y libncurses6:armhf libpulse-dev:armhf libgles2-mesa-dev:armhf libatomic1:armhf libpulse0:armhf libpulse-mainloop-glib0:armhf

# Download Box64 & Box86 Libraries
for box in box86 box64; do
  if command_exists $box; then
    yellow "$box is already installed, skipping..."
    continue
  fi

  if [[ -d "${HOME}/${box}" ]]; then
    rm -rf "${HOME}/${box}"
  fi

  magenta "Downloading $box..."
  export remote=https://github.com/ptitSeb/${box}

  if [[ "${box}" == "box64" ]]; then
    git clone --depth=1 "$remote" "${HOME}/${box}"
  else
    export tag=$(git ls-remote --tags --exit-code --refs "$remote" \
      | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' \
      | sort --version-sort | tail -n1)

    git clone --depth=1 --branch "$tag" "$remote" "${HOME}/${box}"
  fi

  unset tag remote

  green "Installing ${box}"

  cd "${HOME}/${box}"
  mkdir build
  cd build
  if [[ "${box}" == "box64" ]]; then
    cmake .. -DRPI5ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
  else
    cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
  fi
  make -j$(nproc)
  sudo make install
  sudo systemctl restart systemd-binfmt
  cd $HOME
done

if [[ id -u ${CLIENT_USERNAME} > /dev/null 2>&1 ]]; then
  yellow "User already exists."
else
  magenta "Create Local Steam Account"
  sudo useradd -mU -s $(which bash) -p $CLIENT_PASSWORD "${CLIENT_USERNAME}"
fi

yellow "Copying scripts to ${CLIENT_USERNAME}"

if [ -f .env ]; then
  cp .env "/home/${CLIENT_USERNAME}/"
fi
cp ./user-scripts/* "/home/${CLIENT_USERNAME}/"

green "Login to steam account"

sudo su -l "${CLIENT_USERNAME}" --session-command '$HOME/setup.sh'

#green "Install SteamCMD"

#yellow "Hello world: ${SERVER_INSTALL_PATH}"
#if [[ -d ~/steamcmd ]]; then
#  yellow "SteamCMD is already installed, skipping..."
#else
#  mkdir -p ~/steamcmd
#  cd ~/steamcmd
#  curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
#  ./steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +quit

#  magenta "Install Valheim Dedicated Server"

#  ./steamcmd.sh +@sSteamCmdForcePlatformType linux +force_install_dir ~/${SERVER_INSTALL_PATH} +login anonymous +app_update 896660 validate +quit
#  ./steamcmd.sh +@sSteamCmdForcePlatformType linux +force_install_dir ~/valheim_server +login anonymous +app_update 896660 validate +quit

#  # Manually configure the server
#fi
#CMD
