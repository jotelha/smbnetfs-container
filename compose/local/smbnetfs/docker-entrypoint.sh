#!/usr/bin/env bash
#
# smbnetfs/docker-entrypoint.sh
#
# Copyright (C) 2020, IMTEK Simulation
# Author: Johannes Hoermann, johannes.hoermann@imtek.uni-freiburg.de
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#
# Summary:
#
# This entrypoint mounts smb network in userspace
#
set -Eeuox pipefail

echo "Running entrypoint as $(whoami), uid=$(id -u), gid=$(id -g)."

mkdir /mnt/smb

# smbnetfs looks for a user configuration within $HOME/.smb
# and will display a warning if not found.
# Instead, we specify /etc/smbnetfs.conf. Within that file,
# smbnetfs looks for information on how to authenticate for specific
# shares. The option smb_query_browser=false disables automized
# scanning of the local SMB network.
# This entrypoint script runs as root:root. To make the mounted
# share available to user 'mongodb', we specify explicitly
# uid, gid and 'allow_other'.
# NOTE: 'direct_io' possibly obsolete, not teste without.
echo "Mount /mnt/smb."
smbnetfs /mnt/smb -o config=/etc/smbnetfs.conf \
    -o smbnetfs_debug=10 -o log_file=/var/log/smbnetfs.log \
    -o smb_debug_level=10 -o smb_query_browsers=false \
    -o umask=0077 -o direct_io -o allow_other

echo ""
echo "Current mounts:"
mount

# Trapping of SIGTERM for clean unmounting of smb share
# afte mongod shutdown following
# https://medium.com/@gchudnov/trapping-signals-in-docker-containers-7a57fdda7d86
pid=0

# SIGTERM-handler
term_handler() {
  #Cleanup
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  echo "Unmount smb share gracefully."
  fusermount -u /mnt/smb
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, execute the specified handler
trap 'term_handler' SIGTERM
trap 'term_handler' SIGINT

# if no command given, just wait forever (or for external SIGTERM)
if [ -z "$@" ]; then
    # wait forever
    while true; do
        tail -f /dev/null & wait ${!}
    done
# else run command and wait for it to finish or for external SIGTERM
else
    echo  "Evoke '$@'."
    $@ &
    pid="$!"
    wait "$pid"
    ret="$?"
    echo "docker-entrypoint ${@} ended with return code ${ret}".
    echo "Unmount smb share gracefully."
    fusermount -u /mnt/smb
    exit "${ret}"
fi

# http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html
# When Bash receives a signal for which a trap has been set while waiting for a
# command to complete, the trap will not be executed until the command
# completes. When Bash is waiting for an asynchronous command via the wait
# built-in, the reception of a signal for which a trap has been set will cause
# the wait built-in to return immediately with an exit status greater than 128,
# immediately after which the trap is executed.