#!/bin/sh
# Script to replace the base /usr/sbin/cryptsetup symlink with the shim to intercept luksOpen commands

pid="$$"
shim_loc='/usr/local/emhttp/plugins/clevis.unraid/cryptsetup-shim.sh'

# Check if /usr/sbin/cryptsetup is a symlink
if [ ! -L /usr/sbin/cryptsetup ]; then
  /usr/bin/logger -t "clevis.unraid.plugin.install[$pid]" '/usr/sbin/cryptsetup is not a symlink, aborting'
  exit 1
fi

# Check the source script is executable
if [ ! -x "$shim_loc" ]; then
  /usr/bin/logger -t "clevis.unraid.plugin.install[$pid]" "${shim_loc} file is not executable aborting"
  exit 2
fi

# Replace the existing cryptsetup symlink with our shim
#ln -s -f "$shim_loc" /usr/sbin/cryptsetup
#if [ $? -ne 0 ]; then
if ! ln -s -f "$shim_loc" /usr/sbin/cryptsetup; then
 /usr/bin/logger -t "clevis.unraid.plugin.install[$pid]" 'Failed to replace /usr/sbin/cryptsetup symlink aborting'
 exit 3
fi

# Temporary
# Overwrite /usr/bin/clevis-luks-unlock with patched version that allows -o options to be based through clevis
if ! ln -fs /usr/local/emhttp/plugins/clevis.unraid/clevis-luks-unlock /usr/bin/clevis-luks-unlock; then
 /usr/bin/logger -t "clevis.unraid.plugin.install[$pid]" 'Failed to replace /usr/bin/clevis-luks-unlock with patched symlink aborting'
 exit 4
fi

/usr/bin/logger -t "clevis.unraid.plugin.install[$pid]" 'Plugin cryptsetup-shim install successful'