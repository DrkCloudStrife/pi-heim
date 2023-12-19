Valheim Dedicated Server on a Pi
---

Documenting the process to install a dedicated Valheim Server on a Raspberry
Pi 5. Due to the limitations of steamcmd needing to run on x86, and the server
on x64 architecture, we need to install `box86` and `box64` from source since
the Raspberry Pi runs on arm architecture.

## Prerequisites

This was installed on the following Hardware:

* Rasbperry Pi 5 (headless debian)
* Samsung SSD T7 1TB
* USB 3 cable
* Heatsink (optional)
* Ethernet cable (optional)

### Headless OS

I installed the Raspberry Pi OS (64-bit) with [rpi-imager], then ran the command
`sudo raspi-config` to change the configuration to make it headless. I also
configured the image for SSH and network access with this. If you opt against
setting up SSH access through the RPI Imager, you may want to enable it through
the `raspi-config` menu.

```txt
3 Interface Options
I2 VNC Enable/disable graphical remote desktop access
Select <No>
Select <Finish>
```

## Installation

I added a `bootstrap.sh` file for convenience, if you would prefer do run the
process manually, follow the steps below. However, this bootstrap will do the
exact same process.

### Configure environments

Copy `env.example` to `.env`, then configure each argument to your desired
values. If the default values satisfy your needs, then no further action is needed.

To load the configuration to your active shell, run the following:

```sh
export $(grep -v '^#' .env | xargs)
```

### Update Pi to latest version

```sh
sudo dpkg --add-architecture armhf
sudo apt update
sudo apt full-upgrade -y
sudo apt install git build-essential cmake -y
sudo apt install gcc-arm-linux-gnueabihf libc6:armhf libstdc++6:armhf libncurses5:armhf -y
sudo apt install libegl-mesa0:armhf libgdm1:armhf libgl1-mesa-dri:armhf libglapi-mesa:armhf libgles2-mesa:armhf libglu1-mesa:armhf libglx-mesa0:armhf mesa-va-drivers:armhf mesa-vdpau-drivers:armhf mesa-vulkan-drivers:armhf libsdl1.2debian:armhf libudev1:armhf libsdl2-2.0-0:armhf -y
```

### Download box64 and box86

```sh
export remote=https://github.com/ptitSeb/box86
export tag=$(git ls-remote --tags --exit-code --refs "$remote" \
  | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' \
  | sort --version-sort | tail -n1)
git clone --branch "$tag" "$remote" ~/box86
unset tag remote

cd ~/box86
mkdir build
cd build
cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j$(nproc)
sudo make install
sudo systemctl restart systemd-binfmt
cd ~/
rm -rf ~/box86

export remote=https://github.com/ptitSeb/box64
export tag=$(git ls-remote --tags --exit-code --refs "$remote" \
  | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' \
  | sort --version-sort | tail -n1)
git clone --branch "$tag" "$remote" ~/box64
unset tag remote

cd ~/box64
mkdir build
cd build
cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j$(nproc)
sudo make install
sudo systemctl restart systemd-binfmt
cd ~/
rm -rf ~/box64
```

### Create Local Account

```sh
sudo useradd -mU -s $(which bash) -p "${CLIENT_PASSWORD}" "${CLIENT_USERNAME}"
sudo su - "${CLIENT_USERNAME}"
```

### Install SteamCMD

```sh
mkdir -p ~/steamcmd
cd ~/steamcmd
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
./steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +quit
```

### Install Valheim Dedicated Server

```sh
./steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +force_install_dir ~/${SERVER_INSTALL_PATH} +app_update 896660 validate +quit
```

## Configure The Server

## Troubleshooting

In due case that `box64` or `box86` binaries are not working, try installing
an older version or the latest `main` branch.

Known Issues:

* https://github.com/ptitSeb/box86/issues/912

[rpi-imager]:https://www.raspberrypi.com/software/
