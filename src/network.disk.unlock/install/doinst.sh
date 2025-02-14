#!/bin/sh
# Script to replace the base /usr/sbin/cryptsetup symlink with the shim to intercept luksOpen commands

pid="$$"
logger_tag="network.disk.unlock.plugin.install[$pid]"
plugin_loc='/usr/local/emhttp/plugins/network.disk.unlock'
shim_loc="${plugin_loc}/cryptsetup-shim.sh"
pkgs_loc="${plugin_loc}/pkgs"

# Workout what version of unraid we are
if [ -f '/lib64/libcrypto.so.1.1' ]; then
  pkgs_match='unraid-v6'
elif [ -f '/lib64/libcrypto.so.3' ]; then
  pkgs_match='unraid-v7'
else
  echo " ${logger_tag}: Failed to identify compatible version of libcrypto, aborting" >&2
  echo " ${logger_tag}: Local libcrypto version appears to be : $(ls /lib64/libcrypto\.*)" >&2
  /usr/bin/logger -t "$logger_tag" "Failed to identify compatible version of libcrypto, aborting"
  /usr/bin/logger -t "$logger_tag" "Local libcrypto version appears to be : $(ls /lib64/libcrypto\.*)"
  exit 1
fi

# Install all the dependencies for our version of Unraid
for package in "$pkgs_loc"/*_"${pkgs_match}".*.t*; do
  echo "> Installing dependency: $package"
  if ! /sbin/installpkg "$package"; then
    echo " ${logger_tag}: Failed to install package $package, aborting!" >&2
    /usr/bin/logger -t "$logger_tag" "Failed to install package $package, aborting"
    exit 2
  else
    echo "pacakge installed successfully"
  fi

done

echo "> ${logger_tag}: Checking for cryptsetup symlink"
# Check if /usr/sbin/cryptsetup is a symlink
if [ ! -L /usr/sbin/cryptsetup ]; then
  /usr/bin/logger -t "$logger_tag" '/usr/sbin/cryptsetup is not a symlink, aborting'
  exit 11
fi

echo "> ${logger_tag}: Checking for shimm script is executable"
# Check the source script is executable
if [ ! -x "$shim_loc" ]; then
  /usr/bin/logger -t "$logger_tag" "${shim_loc} file is not executable aborting"
  exit 12
fi

# Replace the existing cryptsetup symlink with our shim
#ln -s -f "$shim_loc" /usr/sbin/cryptsetup
#if [ $? -ne 0 ]; then
echo "> ${logger_tag}: Replacing /usr/sbin/cryptsetup symlink with new shim"
if ! ln -s -f "$shim_loc" /usr/sbin/cryptsetup; then
 /usr/bin/logger -t "$logger_tag" 'Failed to replace /usr/sbin/cryptsetup symlink aborting'
 exit 13
fi

# Temporary
# Overwrite /usr/bin/clevis-luks-unlock with patched version that allows -o options to be based through clevis
echo "> ${logger_tag}: Replacing /usr/bin/clevis-luks-unlock with patched version symlink"
if ! ln -fs /usr/local/emhttp/plugins/network.disk.unlock/clevis-luks-unlock /usr/bin/clevis-luks-unlock; then
 /usr/bin/logger -t "$logger_tag" 'Failed to replace /usr/bin/clevis-luks-unlock with patched symlink aborting'
 exit 14
fi

echo "> Creating placeholder keyfile"
# Create an placeholder key file to allow unraid to initiate the disk decryption on start
if [ -f /root/keyfile ]; then
  /usr/bin/logger -t "$logger_tag" 'Prexisting /root/keyfile aborting'
  exit 15
fi
if ! echo 'network.disk.unlock.placeholder' > /root/keyfile; then
  /usr/bin/logger -t "$logger_tag" 'Failed to write to placeholder /root/keyfile aborting'
  exit 16
fi
echo "> ${logger_tag}: Install complete"
/usr/bin/logger -t "$logger_tag" 'Plugin cryptsetup-shim & placeholder keyfile install successful'
