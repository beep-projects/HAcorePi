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
# Checks if any user is holding one of the various lock files used by apt
# and waits until they become available. 
# Warning, you might get stuck forever in here
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
#######################################
function waitForApt() {
  while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
   echo ["$(date +%T)"] waiting for access to apt lock files ...
   sleep 1
  done
}

# CONFIGURATION
HA_DIR="/srv/homeassistant"
VENV_BACKUP="${HA_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
SERVICE_NAME="homeassistant@homeassistant"
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
INSTALL_SCRIPT="${SCRIPT_DIR}/install_latest_python.sh"

CURRENT_USER=$( whoami )
echo "🚀 START update_hacore_venv_to_latest_python.sh as user: ${CURRENT_USER}"
echo "current directory is $( pwd )"

# 🛑 Stop Home Assistant service
echo "🛑 Stopping service: ${SERVICE_NAME}"
sudo systemctl stop ${SERVICE_NAME}

# 🐍 Install latest Python
echo "📦 Running Python installer script: ${INSTALL_SCRIPT}"
bash "${INSTALL_SCRIPT}" || { error "❌ Python installation failed"; }

# 🔍 Determine latest Python binary
#LATEST_PYTHON=$(ls /usr/local/bin/python3.* | sort -V | tail -n 1)
#echo "✅ Latest Python binary detected: ${LATEST_PYTHON}"

# 📁 Backup existing venv
echo "📁 Backing up current Home Assistant venv to: ${VENV_BACKUP}"
sudo mv "${HA_DIR}" "${VENV_BACKUP}"

# 📁 Create new venv directory
echo "📁 Creating new Home Assistant directory..."
sudo mkdir "${HA_DIR}"
sudo chown -R homeassistant:homeassistant "${HA_DIR}"

# 🧪 Create new venv as homeassistant user
echo "🧪 Creating virtual python environment and installing Home Assistant as 'homeassistant'..."

waitForInternet

sudo -u homeassistant -H -s <<EOF
# Create the virtual environment
python -m venv ${HA_DIR}

# Activate the new venv
source ${HA_DIR}/bin/activate

# Upgrade pip and install Home Assistant
pip install --upgrade pip wheel
pip install homeassistant
EOF

# 🔁 Restart service
echo "🔁 Restarting Home Assistant service..."
sudo systemctl start ${SERVICE_NAME}
sleep 3
sudo systemctl status ${SERVICE_NAME}

echo "🎉 Upgrade complete!"
echo "📝 Backup of old environment: ${VENV_BACKUP}"
