#!/usr/bin/env bash

set -euo pipefail
IFS=$' \n\t'

magenta() { echo $'\e[1;35m'$1$'\e[0m'; }
red() { echo $'\e[1;31m'$1$'\e[0m'; }
green() { echo $'\e[1;32m'$1$'\e[0m'; }
yellow() { echo $'\e[1;33m'$1$'\e[0m'; }

generage_pw() { echo $(date +%s%N) | sha256sum | head -c 8; }

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
sudo apt install git build-essential cmake -y
sudo apt install gcc-arm-linux-gnueabihf libc6:armhf libstdc++6:armhf libncurses5:armhf -y
sudo apt install libegl-mesa0:armhf libgdm1:armhf libgl1-mesa-dri:armhf libglapi-mesa:armhf libgles2-mesa:armhf libglu1-mesa:armhf libglx-mesa0:armhf mesa-va-drivers:armhf mesa-vdpau-drivers:armhf mesa-vulkan-drivers:armhf libsdl1.2debian:armhf libudev1:armhf libsdl2-2.0-0:armhf -y

# Download Box64 & Box86 Libraries
for box in box86 box64; do
  export remote=https://github.com/ptitSeb/${box}
  export tag=$(git ls-remote --tags --exit-code --refs "$remote" \
    | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' \
    | sort --version-sort | tail -n1)
  magenta "Downloading $remote version $tag"
  git clone --branch "$tag" "$remote" ~/${box}
  unset tag remote

  green "Installing ${box}"

  cd ~/${box}
  mkdir build
  cd build
  cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
  make -j$(nproc)
  sudo make install
  sudo systemctl restart systemd-binfmt
  cd ~/
  rm -rf ~/${box}
done

magenta "Create Local Steam Account"

sudo useradd -mU -s $(which bash) -p "${CLIENT_PASSWORD}" "${CLIENT_USERNAME}"

green "Login to steam account"

sudo su - "${CLIENT_USERNAME}"

green "Install SteamCMD"

mkdir -p ~/steamcmd
cd ~/steamcmd
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
./steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +quit

magenta "Install Valheim Dedicated Server"

./steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +force_install_dir ~/${SERVER_INSTALL_PATH} +app_update 896660 validate +quit

# Configure the server
