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


# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.

# Raspberry Pi OS with desktop
# raspios_armhf
# raspios_arm64
# Raspberry Pi OS with desktop and recommended software
# raspios_full_armhf
# raspios_full_arm64
# Raspberry Pi OS Lite"
# raspios_lite_armhf
# raspios_lite_arm64

# armhf
# 32bit

# arm64
# 64bit
# 3B
# 3B+
# 3A+
# 4B
# 400
# 5
# CM3
# CM3+
# CM4
# CM4S
# Zero 2 W

RASPI_OS_PLATFORM="_armhf" # "arm64"
RASPI_OS_TYPE="_lite" # "full" "desktop"
RASPI_OS_ID="raspios_lite_armhf"
RASPI_OS_RELEASE_FILE="operating-systems-categories.json"
RPI_IMAGE_URL=""
RPI_IMAGE_HASH_URL=""
RPI_IMAGE_XZ=""
RPI_IMAGE_HASH=""
RPI_IMAGE=""

VERBOSE="false"

# save the arguments in case they are required later
ARGS=$*

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

#######################################
# Print passed messages if global variable VERBOSE="true".
# Globals:
#   VERBOSE = echo arguments if true
# Arguments:
#   $@ = Everything you want to echo
# Outputs:
#   Echos text to stdout
#######################################
function verbose() {
    [ "${VERBOSE}" = "true" ] && echo "${@}"
}

#######################################
# Checks if the internet can be accessed
# and waits until they become available. 
# Warning, you might get stuck forever in here
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
#######################################
function waitForInternet() {
  until nc -zw1 google.com 443 >/dev/null 2>&1;  do
    #newer Raspberry Pi OS versions do not have nc preinstalled, but wget is still there
    if wget -q --spider http://google.com; then
      break # we are online
    else
      #we are still offline
      # display status message
      verbose ["$(date +%T)"] waiting for internet access ...
      sleep 1
    fi
  done
}

#######################################
# Show help.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Prints usage information to stdout
#######################################
function help() {
cat <<END
  download_RaspiOS_image.sh: Script to download the latest Raspberry Pi OS image.
  
  Parameters are :
    -h/-?/--help                      display this help and exit
    -p/--plattform <plattform>        plattform for which the OS should be downloaded: armhf, 32bit (older pis, default) or arm64, 64bit
    -t/--type <type>                  type of Raspberry Pi OS that should be downloaded: normal (Raspberry Pi OS with desktop), full (Raspberry Pi OS with desktop and recommended software), lite (no desktop, default)
    -u/--url <url>                    URL of the image file that should be downloaded. If the URL is given, --type and --plattform are ignored
    -v/--verbose                      explain what is being done

  Example:
    ./download_RaspiOS_image.sh --verbose --plattform 64bit --type lite

END
}

# -------------------------------------------------------
#   Loop to load arguments
# -------------------------------------------------------

# if no argument, display help
#if [ $# -eq 0 ] 
#then
#  help
#fi

# loop to retrieve arguments
while :; do
  case $1 in
    -h|-\?|--help)
      help # show help for this script
      exit 0
      ;;
    -p|--plattform)
      if [ "$2" ]; then
        case $2 in
          armhf|32bit)
            RASPI_OS_PLATFORM="_armhf"
          ;;
          arm64|64bit)
            RASPI_OS_PLATFORM="_arm64"
          ;;
          *)
            error "unknown value ${2} for parameter ${1}"
          esac
        shift
      else
        error "${1} requires a non-empty option argument."
      fi
      ;;
    -t|--type)
      if [ "$2" ]; then
        case $2 in
          normal)
            RASPI_OS_TYPE=""
          ;;
          full|lite)
            RASPI_OS_TYPE="_${2}"
          ;;
          *)
            error "unknown value \"${2}\" for parameter ${1}"
          esac
        shift
      else
        error "${1} requires a non-empty option argument"
      fi
      ;;
    -u|--url)
      if [ "$2" ]; then
        # validate the URL
        if [[ "${2}" =~ ^https:\/\/downloads\.raspberrypi\.com.*[0-9]{4}-[0-9]{2}-[0-9]{2}-raspios-[a-z]*-(armhf|arm64)(-full|-lite)?\.img\.xz$ ]]; then
          RPI_IMAGE_URL="${2}"
        else
          error "${2} does not have a known format for the  download URL. If your entry is correct, please request an update of this script."
        fi
        shift
      else
        error "${1} requires a non-empty option argument"
      fi
      ;;
    -v|--verbose)
      VERBOSE="true"
      ;;
    --) # End of all options.
      shift
      break
      ;;
    -?*)
      printf "WARN: Unknown option (ignored): %s\n" "${1}" >&2
      ;;
    *) # Default case: No more options, so break out of the loop.
      break
  esac
  shift
done

# Single function
function main() {

  verbose "command:" "${0}" "${ARGS}"

  RASPI_OS_ID="raspios${RASPI_OS_TYPE}${RASPI_OS_PLATFORM}"

  verbose "RASPI_OS_ID:" "${RASPI_OS_ID}"

  waitForInternet

  if [[ -z "${RPI_IMAGE_URL}" ]]; then
    verbose 
    verbose "=============================================================="
    verbose " get latest Raspberry Pi OS image"
    verbose "=============================================================="
    verbose 
    verbose "get rasbian os information data from server";
    rm "${RASPI_OS_RELEASE_FILE}" 2> /dev/null # ignore if file does not exist
    wget -q "https://downloads.raspberrypi.org/${RASPI_OS_RELEASE_FILE}"

    RPI_IMAGE_URL=$( <${RASPI_OS_RELEASE_FILE} grep "${RASPI_OS_ID}" | grep urlHttp | sed -e 's/.*\: \"\(.*\)\".*/\1/' )
    verbose "latest image URL is: ${RPI_IMAGE_URL}"
  fi

  RPI_IMAGE_HASH_URL="${RPI_IMAGE_URL}.sha256"

  verbose 
  verbose "=============================================================="
  verbose " download and check Raspberry Pi OS"
  verbose "=============================================================="
  verbose 

  RPI_IMAGE_XZ=$(basename "${RPI_IMAGE_URL}")
  RPI_IMAGE_HASH=$(basename "${RPI_IMAGE_HASH_URL}")
  RPI_IMAGE="${RPI_IMAGE_XZ//.xz/}"

  if [ -f "${RPI_IMAGE}" ]; then
    verbose "${RPI_IMAGE} file found. Skipping download."
  elif [ -f "${RPI_IMAGE_XZ}" ]; then
    verbose "${RPI_IMAGE_XZ} file found. Skipping download."
  else
    verbose "downloading Raspberry Pi OS image from server. please wait ..."
    rm   "${RPI_IMAGE_XZ}.downloading" 2> /dev/null # ignore if file does not exist
    wget -q "${RPI_IMAGE_URL}" -O "${RPI_IMAGE_XZ}.downloading"
    mv   "${RPI_IMAGE_XZ}.downloading" "${RPI_IMAGE_XZ}"

    verbose "downloading hash file for image file from server. please wait ..."
    rm "${RPI_IMAGE_HASH}" 2> /dev/null # ignore if file does not exist
    wget -q "${RPI_IMAGE_HASH_URL}"

    verbose "checking hash value of image file"
    HASH_OK=$( sha256sum -c "${RPI_IMAGE_HASH}" | grep "${RPI_IMAGE_XZ}: OK" )
    if [ -z "${HASH_OK}" ]; then
      error "hash does not match, aborting"
    else
      verbose "hash is ok"
    fi
  fi

  verbose 
  verbose "=============================================================="
  verbose " extract image file"
  verbose "=============================================================="
  verbose 

  verbose "extract the Raspberry Pi OS image"
  if [ -f "${RPI_IMAGE}" ]; then
    verbose "file found, skip the extract"
  else
    verbose "extracting file. please wait a few minutes ..."
    verbose "unxz ${RPI_IMAGE_XZ}"
    unxz "${RPI_IMAGE_XZ}"
  fi

  # return name of downloaded image file
  echo "${RPI_IMAGE}"
  exit 0
}

main "$@"