#!/bin/sh

pid="$$"
logger_tag="network.disk.unlock.plugin.install[$pid]"

# Replace the original cryptsetup symlink with the original
echo "> Restoring /usr/sbin/cryptsetup symlink"
if [ -L /usr/sbin/cryptsetup ]; then
  ln -s -f '../../sbin/cryptsetup' /usr/sbin/cryptsetup
  if ! ln -s -f '../../sbin/cryptsetup' /usr/sbin/cryptsetup; then
    echo "Failed to restore unraid /usr/sbin/cryptsetup symlink to '../../sbin/cryptsetup', continuing" >&2
    /usr/bin/logger -t "$logger_tag" "Failed to restore unraid /usr/sbin/cryptsetup symlink to '../../sbin/cryptsetup', continuing"
  fi
fi

# ToDo: Fix the versioning of clevis and jose so versions are not needed here
echo "> Removing package clevis"
if ! /sbin/removepkg clevis-20; then
  echo "Failed to remove clevis package, continuing" >&2
  /usr/bin/logger -t "$logger_tag" "Failed to remove clevis package, continuing"
fi

echo "> Removing package jose"
if ! /sbin/removepkg jose-12; then
  echo "Failed to remove jose package, continuing" >&2
  /usr/bin/logger -t "$logger_tag" "Failed to remove jose package, continuing"
fi

echo "> Finished uninstalling network.disk.unlock plugin"
