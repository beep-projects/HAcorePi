#!/usr/bin/bash
#
# Copyright (c) 2021-2024, The beep-projects contributors
# this file originated from https://github.com/beep-projects
# Do not remove the lines above.
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see https://www.gnu.org/licenses/
#
# bash flash_HAcorePi.sh ;
# or pass the path of the sdcard
# bash flash_HAcorePi.sh /dev/mmcblk0 ;

#######################################
# Print error message.
# Globals:
#   None
# Arguments:
#   $1 = Error message
#   $2 = return code (optional, default 1)
# Outputs:
#   Prints an error message to stderr
#######################################
function error() {
    printf "%s\n" "${1}" >&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

echo 
echo "=============================================================="
echo " WARNING  WARNING  WARNING  WARNING  WARNING  WARNING  WARNING"
echo "=============================================================="
echo 
echo "This script will make use of dd to flash a SD card. This has the potential to break your system."
echo "By continuing, you confirm that you know what you are doing and that you will double check every step of this script"
read -rp "press Y to continue " -n 1 -s
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi 

echo 
echo "=============================================================="
echo " initializing script"
echo "=============================================================="
echo 

# SD card path
if [ "${1}" ]; then
  SD_CARD_PATH="${1}"
else
  SD_CARD_PATH="/dev/mmcblk0"
fi

#RPI_IMAGE_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-09-07/2022-09-06-raspios-bullseye-armhf-lite.img.xz"
#RPI_IMAGE_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2023-10-10/2023-10-10-raspios-bookworm-armhf-lite.img.xz"
#RPI_IMAGE_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2023-12-11/2023-12-11-raspios-bookworm-armhf-lite.img.xz"
RPI_IMAGE_URL="https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-11-19/2024-11-19-raspios-bookworm-arm64-lite.img.xz"
USE_LATEST_RASPI_OS=false
RASPI_OS_TYPE="lite"
RASPI_OS_PLATTFORM="64bit"
RPI_IMAGE="unknown"

#get HOSTNAME for raspberry pi from firstrun.sh
RPI_HOST_NAME=$( grep "^HOSTNAME=" scripts/firstrun.sh | cut -d "=" -f 2 )
#get USERNAME for raspberry pi from firstrun.sh
RPI_USER_NAME=$( grep "^USERNAME=" scripts/firstrun.sh | cut -d "=" -f 2 )

echo "SD_CARD_PATH = ${SD_CARD_PATH}"
echo "RPI_HOST_NAME = ${RPI_HOST_NAME}"

echo 
echo "=============================================================="
echo " check SD card path"
echo "=============================================================="
echo 

echo "please make sure that your SD card is inserted into this computer"
echo "press any key, when you are ready ..."
read -rn 1 -s
echo

DISKNAME=$( echo "${SD_CARD_PATH}" | rev | cut -d "/" -f 1 | rev )

if ! lsblk | grep -q "${DISKNAME}" ; then
  error "FAIL: Disk with name ${DISKNAME} not found, exiting"
fi

echo "CHECK OK: Disk with name ${DISKNAME} exists"

if [ -b "${SD_CARD_PATH}" ]; then
  echo "CHECK OK: Path ${SD_CARD_PATH} exists"
else
  error "FAIL: SD card at ${SD_CARD_PATH} not found, exiting"
fi
echo

#show available disks for final check
echo "=============================================================="
echo " available disks"
echo "=============================================================="
echo
echo "lsblk | grep disk"
lsblk | grep disk
echo

echo "This script will dd an image of Raspberry Pi OS over whatever is located at"
echo "        ${SD_CARD_PATH}"
echo "Please check the above listing and confirm that you want to write the image to ${SD_CARD_PATH}"
read -rp "Press Y to continue" -n 1 -s
echo
if [[ ! "${REPLY}" =~ ^[Yy]$ ]]; then
    exit 1
fi 
echo

if [[ ${USE_LATEST_RASPI_OS} == true ]] ; then
  echo 
  echo "=============================================================="
  echo " get latest Raspberry Pi OS ${RASPI_OS_PLATTFORM} image"
  echo "=============================================================="
  echo 

  RPI_IMAGE=$( ./download_RaspiOS_image.sh --plattform ${RASPI_OS_PLATTFORM} --type ${RASPI_OS_TYPE} )
else 
  echo 
  echo "=============================================================="
  echo " get Raspberry Pi OS image from ${RPI_IMAGE_URL}"
  echo "=============================================================="
  echo 

  RPI_IMAGE=$( ./download_RaspiOS_image.sh --url ${RPI_IMAGE_URL} )
fi

echo "got image file: ${RPI_IMAGE}"

echo 
echo "=============================================================="
echo " write image to SD card"
echo "=============================================================="
echo 

echo "unmount SD card $DISKNAME"
#echo "press any key to continue..."
#read -rn 1 -s

mount | grep "${DISKNAME}" | cut -d " " -f 3 | while read -r line ; do
    echo "sudo umount ${line}"
    sudo umount "${line}"
done
echo

echo "SD card used for the following operations is located at: ${SD_CARD_PATH}"
#echo "press any key to continue..."
#read -rn 1 -s
#echo

echo "wipe SD card: sudo wipefs -a ${SD_CARD_PATH}"
#echo "press any key to continue..."
#read -rn 1 -s
sudo wipefs -a "${SD_CARD_PATH}"
echo

echo "write image file to SD card: sudo dd bs=8M if=${RPI_IMAGE} of=${SD_CARD_PATH} status=progress"
#echo "press any key to continue..."
#read -rn 1 -s
#echo "writing image to SD card ..."
sudo dd bs=8M if="${RPI_IMAGE}" of="${SD_CARD_PATH}" status=progress
echo

echo 
echo "=============================================================="
echo " mount SD card"
echo "=============================================================="
echo 
sleep 3 #give the system some time to detect the new formatted disks

echo "mount SD card"
UUID=$( lsblk -f | grep "${DISKNAME}" | grep boot | rev | xargs | cut -d " " -f1 | rev )
echo "udisksctl mount -b \"/dev/disk/by-uuid/${UUID}\""
udisksctl mount -b "/dev/disk/by-uuid/${UUID}"
RPI_PATH=$( mount | grep "${DISKNAME}" | cut -d " " -f 3 )

#echo "press any key to continue..."
#read -rn 1 -s
#echo

echo 
echo "=============================================================="
echo " setting root=PARTUUID in cmdline.txt"
echo "=============================================================="
echo 

echo "the UUID of the root partition might have changed for the downloaded image. Updating the entry in cmdline.txt"
PARTUUID=$( sudo blkid | grep rootfs | grep -oP '(?<=PARTUUID=\").*(?=\")' )
echo "set PARTUUID=$PARTUUID for rootfs in scripts/cmdline.txt"
sed -i "s/\(.*PARTUUID=\)[^ ]*\( .*\)/\1$PARTUUID\2/" scripts/cmdline.txt

echo 
echo "=============================================================="
echo " copy files to SD card"
echo "=============================================================="
echo 

echo "copy files to ${RPI_PATH}"
echo "cp scripts/* ${RPI_PATH}"
cp scripts/* "${RPI_PATH}"
echo "cp *.tar ${RPI_PATH}"
cp *.tar "${RPI_PATH}"
echo

#echo "press any key to continue..."
#read -rn 1 -s
#echo

echo 
echo "=============================================================="
echo " unmount SD card"
echo "=============================================================="
echo 

echo "unmount SD card"
sudo umount "${RPI_PATH}"
echo "all work is done. Please insert the SD card into your raspberry pi"
echo "NOTE: when starting up, your raspberry pi should reboot 4 times until"
echo "      all setup work is finished and home assistant is up and running."
echo "      Be patient!"

echo
echo "///////////////////////////////////////////////////////////////"
echo
echo "               ssh -x ${RPI_USER_NAME}@${RPI_HOST_NAME}"
echo "               tail -f /boot/secondrun.log"
echo "               http://${RPI_HOST_NAME}:8123"
echo
echo "///////////////////////////////////////////////////////////////"
echo
exit 0;
