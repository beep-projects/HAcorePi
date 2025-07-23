# HAcorePi

HAcorePi is a set of scripts to install Home Assistant Core on a Raspberry Pi. It is designed to be a simple and easy way to get started with Home Assistant on a Raspberry Pi.  
Note: The Core installation method is deprecated and official support endes with Homeassistant release 2025.12. From that on the installation method should still work, but you will not get support from the official project.

## Table of Contents

- [Project Installation](#project-installation)
- [Scripts](#scripts)
  - [download\_RaspiOS\_image.sh](#download_raspios_imagesh)
  - [flash\_HAcorePi.sh](#flash_hacorepish)
  - [scripts/cmdline.txt](#scriptscmdlinetxt)
  - [scripts/firstrun.sh](#scriptsfirstrunsh)
  - [scripts/install\_hacore.sh](#scriptsinstall_hacoresh)
  - [scripts/install\_latest\_python.sh](#scriptsinstall_latest_pythonsh)
  - [scripts/secondrun.sh](#scriptssecondrunsh)
  - [scripts/thirdrun.sh](#scriptsthirdrunsh)
  - [scripts/update\_hacore.sh](#scriptsupdate_hacoresh)
  - [scripts/update\_hacore\_venv\_to\_latest\_python.sh](#scriptsupdate_hacore_venv_to_latest_pythonsh)

## Project Installation

This guide will walk you through the process of setting up HAcorePi on a Raspberry Pi. The two main scripts for the installation are `flash_HAcorePi.sh` and `firstrun.sh`. `flash_HAcorePi.sh` is used to flash the Raspberry Pi OS image to an SD card, and `firstrun.sh` is used to configure the Raspberry Pi on the first boot.

### Linux

1.  **Download the project from GitHub:**

    ```bash
    git clone https://github.com/beep-projects/HAcorePi.git
    cd HAcorePi
    ```

2.  **Configure `firstrun.sh`:**

    Open `scripts/firstrun.sh` in a text editor and modify the configuration section to your needs. You will need to set the `HOSTNAME`, `USERNAME`, `PASSWD`, `SSID`, and `WPA_PASSPHRASE` variables.

    ```bash
    #-------------------------------------------------------------------------------
    #----------------------- START OF CONFIGURATION --------------------------------
    #-------------------------------------------------------------------------------

    #---------- VARIABLES THAT SHOULD BE COPIED INTO secondrun.sh ------------------
    # The idea for this is, that all configuration can be done in this file
    # use the last tested ELK stack, or the newest one
    #VARIABLE_NAME=variable_value

    #---------- VARIABLES USED IN firstrun.sh ------------------
    # which hostname do you want to give your raspberry pi?
    HOSTNAME=hacorepi
    # username: beep, password: projects
    # you can change the password if you want and generate a new password with
    # Linux: mkpasswd --method=SHA-256
    # Windows: you can use an online generator like https://www.dcode.fr/crypt-hasing-function
    USERNAME=beep
    # shellcheck disable=SC2016
    PASSWD='$5$oLShbrSnGq$nrbeFyt99o2jOsBe1XRNqev5sWccQw8Uvyt8jK9mFR9' #keep single quote to avoid expansion of $
    # configure the wifi connection
    # the example WPA_PASSPHRASE is generated via
    #     wpa_passphrase MY_WIFI passphrase
    # but you also can enter your passphrase as plain text, if you accept the potential insecurity of that approach
    SSID=MY_WIFI
    WPA_PASSPHRASE=3755b1112a687d1d37973547f94d218e6673f99f73346967a6a11f4ce386e41e
    # set your locale, get all available: cat /usr/share/i18n/SUPPORTED
    LOCALE="de_DE.UTF-8"
    # configure your timezone and key board settings
    TIMEZONE="Europe/Berlin"
    COUNTRY="DE"
    XKBMODEL="pc105"
    XKBLAYOUT=$COUNTRY
    XKBVARIANT=""
    XKBOPTIONS=""

    #-------------------------------------------------------------------------------
    #------------------------ END OF CONFIGURATION ---------------------------------
    #-------------------------------------------------------------------------------
    ```

3.  **Flash the SD card:**

    Run the `flash_HAcorePi.sh` script to flash the Raspberry Pi OS image to your SD card. Make sure to replace `/dev/mmcblk0` with the correct path to your SD card.

    ```bash
    ./flash_HAcorePi.sh /dev/mmcblk0
    ```

4.  **Boot the Raspberry Pi:**

    Insert the SD card into your Raspberry Pi and power it on. The Raspberry Pi will reboot several times during the installation process. 
    For troubleshooting, you can check the progress by checking the logs. After a few minutes the resize of the partitions and `firstrun.sh` should be finished, once `secondrun.sh` is running you can ssh into the systapi and watch the installation process. Default user is `beep` with password `projects`.

    ```bash
    ssh -x beep@hacorepi.local
    tail -f /boot/secondrun.log
    ```
    After the installation is complete, you will be able to access Home Assistant at `http://hacorepi:8123`.

## Scripts

### [download\_RaspiOS\_image.sh](download_RaspiOS_image.sh)

This script downloads the latest Raspberry Pi OS image. You can specify the platform (32-bit or 64-bit) and the type of image (Lite, Desktop, or Full).

**Usage:**

```bash
./download_RaspiOS_image.sh [options]
```

**Options:**

*   `-h, --help`: Display this help and exit.
*   `-p, --plattform <plattform>`: The platform for which the OS should be downloaded: `armhf`, `32bit` (older pis, default) or `arm64`, `64bit`.
*   `-t, --type <type>`: The type of Raspberry Pi OS that should be downloaded: `normal` (Raspberry Pi OS with desktop), `full` (Raspberry Pi OS with desktop and recommended software), `lite` (no desktop, default).
*   `-u, --url <url>`: The URL of the image file that should be downloaded. If the URL is given, `--type` and `--plattform` are ignored.
*   `-v, --verbose`: Explain what is being done.

### [flash\_HAcorePi.sh](flash_HAcorePi.sh)

This script flashes a Raspberry Pi OS image to an SD card. It also copies the necessary scripts to the SD card to set up Home Assistant Core.

**Usage:**

```bash
./flash_HAcorePi.sh [sd_card_path]
```

**Arguments:**

*   `sd_card_path`: The path to the SD card (e.g., `/dev/mmcblk0`).

### [scripts/cmdline.txt](scripts/cmdline.txt)

This file contains the kernel command line parameters. It is used to run the `firstrun.sh` script on the first boot.

### [scripts/firstrun.sh](scripts/firstrun.sh)

This script is run on the first boot of the Raspberry Pi. It sets up the hostname, user, password, and Wi-Fi connection. It also sets up the `secondrun.service` to be started after the next boot.

### [scripts/install\_hacore.sh](scripts/install_hacore.sh)

This script installs Home Assistant Core. It creates a `homeassistant` user and group, creates a virtual environment, and installs the required Python packages.

### [scripts/install\_latest\_python.sh](scripts/install_latest_python.sh)

This script installs the latest version of Python. It is used by the `secondrun.sh` script.

### [scripts/secondrun.sh](scripts/secondrun.sh)

This script is run on the second boot of the Raspberry Pi. It updates the system, installs the latest version of Python, and installs Home Assistant Core.

### [scripts/thirdrun.sh](scripts/thirdrun.sh)

This script is run on the third boot of the Raspberry Pi. It cleans up the files that were used during the installation process.

### [scripts/update\_hacore.sh](scripts/update_hacore.sh)

This script updates an existing Home Assistant Core installation.

### [scripts/update\_hacore\_venv\_to\_latest\_python.sh](scripts/update_hacore_venv_to_latest_python.sh)

This script updates the Python virtual environment for Home Assistant Core to the latest version of Python.