#!/bin/bash
#
# Copyright (c) 2024, The beep-projects contributors
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
# This file will install Python 3.13.1 following
# https://aruljohn.com/blog/python-raspberrypi/
#

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

CURRENT_USER=$( whoami )
echo "START install_latest_python.sh as user: ${CURRENT_USER}"
echo "current directory is $( pwd )"
# install the build tools
waitForInternet
waitForApt
sudo apt update
#sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev  libsqlite3-dev
sudo apt install -y build-essential gdb lcov pkg-config \
      libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
      libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
      lzma lzma-dev tk-dev uuid-dev zlib1g-dev
# get latest python version
latest_python_version=$(curl -L --compressed "https://www.python.org/downloads/source/" 2> /dev/null \
                | grep -o "href.*Latest Python 3 Release.*" \
                | grep -o 'Python [0-9]*\.[0-9]*\.[0-9]*' \
                | cut -d ' ' -f 2)
# download the Python source code
# for some reason wget could not access the certificates
wget --no-check-certificate "https://www.python.org/ftp/python/${latest_python_version}/Python-${latest_python_version}.tar.xz"
tar -xvf "Python-${latest_python_version}.tar.xz"
cd "Python-${latest_python_version}/"
./configure --enable-optimizations --enable-shared --with-lto
sudo make altinstall
# make current minor version the default python
latest_python_minor_version=${latest_python_version%.*}
sudo rm /usr/bin/python
sudo ln -s "/usr/local/bin/python${latest_python_minor_version}" /usr/bin/python
sudo rm /usr/bin/python3
sudo ln -s "/usr/local/bin/python${latest_python_minor_version}" /usr/bin/python3
sudo rm /usr/bin/pip
sudo ln -s "/usr/local/bin/pip${latest_python_minor_version}" /usr/bin/pip
sudo rm /usr/bin/pip3
sudo ln -s "/usr/local/bin/pip${latest_python_minor_version}" /usr/bin/pip3
# export the shared libs
cat >> /etc/ld.so.conf.d/local_libs.conf << 'END'
# shared libs of locally built python${latest_python_version} and others
/usr/local/lib
END
sudo ldconfig
# test version
echo "available python version is:"
python -VV

# this is missing in the guide
echo "pip install --upgrade pip"
pip install --upgrade pip

echo "pip install virtualenv"
pip install virtualenv

echo "END install_latest_python.sh"
