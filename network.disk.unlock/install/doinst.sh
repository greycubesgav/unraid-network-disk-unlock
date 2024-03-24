#!/bin/sh
# Script to replace the base /usr/sbin/cryptsetup symlink with the shim to intercept luksOpen commands

pid="$$"
logger_tag="network.disk.unlock.plugin.install[$pid]"
shim_loc='/usr/local/emhttp/plugins/network.disk.unlock/cryptsetup-shim.sh'

# Check if /usr/sbin/cryptsetup is a symlink
if [ ! -L /usr/sbin/cryptsetup ]; then
  /usr/bin/logger -t "$logger_tag" '/usr/sbin/cryptsetup is not a symlink, aborting'
  exit 1
fi

# Check the source script is executable
if [ ! -x "$shim_loc" ]; then
  /usr/bin/logger -t "$logger_tag" "${shim_loc} file is not executable aborting"
  exit 2
fi

# Replace the existing cryptsetup symlink with our shim
#ln -s -f "$shim_loc" /usr/sbin/cryptsetup
#if [ $? -ne 0 ]; then
if ! ln -s -f "$shim_loc" /usr/sbin/cryptsetup; then
 /usr/bin/logger -t "$logger_tag" 'Failed to replace /usr/sbin/cryptsetup symlink aborting'
 exit 3
fi

# Temporary
# Overwrite /usr/bin/clevis-luks-unlock with patched version that allows -o options to be based through clevis
if ! ln -fs /usr/local/emhttp/plugins/network.disk.unlock/clevis-luks-unlock /usr/bin/clevis-luks-unlock; then
 /usr/bin/logger -t "$logger_tag" 'Failed to replace /usr/bin/clevis-luks-unlock with patched symlink aborting'
 exit 4
fi

# Create an placeholder key file to allow unraid to initiate the disk decryption on start
if [ -f /root/keyfile ]; then
  /usr/bin/logger -t "$logger_tag" 'Prexisting /root/keyfile aborting'
  exit 5
fi
if ! echo 'keyfile' > /root/keyfile; then
  /usr/bin/logger -t "$logger_tag" 'Failed to write to placeholder /root/keyfile aborting'
  exit 6
fi

/usr/bin/logger -t "$logger_tag" 'Plugin cryptsetup-shim & placeholder keyfile install successful'
