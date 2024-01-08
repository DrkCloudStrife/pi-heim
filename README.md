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

```sh
sudo raspi-config
# 1 System Options > S5 Boot/Auto Login > B2 Console Autologin
# 3 Interface Options > I2 VNC Enable/disable graphical remote desktop access
# Reboot
```

## Converting ps16k to ps4k Kernel

Due to issues with [box86 ps16k][box86_libm_offset], we need to rebuild
the kernel to be ps4k.

Follow the instructions here: [RPI Kernel][rpi_kernel]

Change `CONFIG_LOCALVERSION` from `-v8-16k` to `-v8-4k`

>**Note:** This will take some time

### Switching ps16k to ps4k

If rebuilding the kernel is not an option, it looks like PiOS has both kernels
available and you can simply change it by modifying the
`/boot/firmware/config.txt` with `kernel=kernel8.img`

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
sudo apt install gcc-arm-linux-gnueabihf libc6:armhf libstdc++6:armhf libncurses5:armhf libncurses6:armhf -y
sudo apt install libncurses6:armhf libpulse-dev:armhf libgles2-mesa-dev:armhf libatomic1:armhf libpulse0:armhf libpulse-mainloop-glib0:armhf -y
# sudo apt install libegl-mesa0:armhf libgdm1:armhf libgl1-mesa-dri:armhf libglapi-mesa:armhf libgles2-mesa:armhf libglu1-mesa:armhf libglx-mesa0:armhf mesa-va-drivers:armhf mesa-vdpau-drivers:armhf mesa-vulkan-drivers:armhf libsdl1.2debian:armhf libudev1:armhf libsdl2-2.0-0:armhf -y
```

### Install experimental and unstable libraries

>**NOTE:** These are not installed by the boothstrap script, these should only
>be manually installed if your server is not working after setting it up.

```sh
sudo vi /etc/apt/sources.list
# deb https://deb.debian.org/debian experimental main
deb https://deb.debian.org/debian testing main
deb https://deb.debian.org/debian unstable main
sudo apt update
# sudo apt install -t experimental libsdl3-0:armhf libsdl3-dev:armhf -y
sudo apt install -t testing libdecor-0-0:armhf libpulse-mainloop-glib0:armhf -y
sudo apt install -t testing libpulse-mainloop-glib0:armhf
```

### Download box64 and box86

```sh
export remote=https://github.com/ptitSeb/box86
export tag=$(git ls-remote --tags --exit-code --refs "$remote" \
  | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' \
  | sort --version-sort | tail -n1)
git clone --depth=1 --branch "$tag" "$remote" ~/box86
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
git clone --depth=1 --branch "$tag" "$remote" ~/box64
unset tag remote

cd ~/box64
mkdir build
cd build
cmake .. -DRPI5ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
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

>**NOTE:** You are in a different user, your ENV variables do not carry over.
>Leaving the `ENV` variables here for references, but you may need to manually
change them for it to work properly.

### Install SteamCMD

```sh
mkdir -p ~/steamcmd
cd ~/steamcmd
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
./steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +quit
```

### Install Valheim Dedicated Server

```sh
./steamcmd.sh +@sSteamCmdForcePlatformType linux +force_install_dir ~/${SERVER_INSTALL_PATH} +login anonymous +app_update 896660 validate +quit
```

## Configure The Server

```sh
cd ~/${SERVER_INSTALL_PATH}
vi start_server.sh
# Change the following line to your liking
# ./valheim_server.x86_64 -name "My server" -port 2456 -world "Dedicated" -password "secret" -crossplay
# For more info read the provided PDF or look at https://valheim.fandom.com/wiki/Valheim_Dedicated_Server#Step_2:_Setting_up_a_Valheim_Dedicated_Server
# To speficy a save directory for the worlds, use `-savedir /path/to/save-dir/`
```

## Troubleshooting

In due case that `box64` or `box86` binaries are not working, try installing
an older version or the latest `main` branch.

Known Issues:

* [https://github.com/ptitSeb/box86/issues/912][box86_libm_offset]

[rpi-imager]: https://www.raspberrypi.com/software/
[box86_libm_offset]: https://github.com/ptitSeb/box86/issues/912
[rpi_kernel]: https://www.raspberrypi.com/documentation/computers/linux_kernel.html#building-the-kernel-locally
