#!/bin/sh

# Shim to replace a crypysetp luksOpen command with a clevis open
# If the clevis open fails, pass over silently to cryptsetup
# /usr/sbin/cryptsetup luksOpen /dev/%s %s %s
# /usr/bin/clevis luks unlock -d /dev/%s -n %s

pid="$$"
logger_tag="cryptsetup-shim[$pid]"
printf '%s ' 'shim executed with arguments' "$*" | /usr/bin/logger -t "$logger_tag"

# Check if the first argument is "luksOpen"
if [ "$1" = "luksOpen" ]; then
    # We should be one of
    # 1        2         3    4                        5
    # luksOpen /dev/sde1 sde1
    # luksOpen /dev/sde1 sde1 --allow-discards
    # luksOpen /dev/sde1 sde1 --key-file=/root/keyfile
    # luksOpen /dev/sde1 sde1 --allow-discards         --key-file=/root/keyfile
    if [ -n "$4" ] && [ "$4" != '--key-file=/root/keyfile' ]; then
      # We pass this option on to clevis
      /usr/bin/logger -t "$logger_tag" " rerouting to {/usr/bin/clevis luks unlock -d \"$2\" -n \"$3\" -o \"$4\"}"
      if ! /usr/bin/clevis luks unlock -d "$2" -n "$3" -o "$4"; then
        /usr/bin/logger -t "$logger_tag" "  failed to unlock with clevis, passing through to real /sbin/cryptsetup"
        /sbin/cryptsetup "$@"
      else
        /usr/bin/logger -t "$logger_tag" "  succesfully unlocked with clevis device \"$2\" --options \"$4\""
      fi
    else
      # We don't pass any option over to clevis
      /usr/bin/logger -t "$logger_tag" " rerouting to {/usr/bin/clevis luks unlock -d \"$2\" -n \"$3\"}"
      if ! /usr/bin/clevis luks unlock -d "$2" -n "$3"; then
        /usr/bin/logger -t "$logger_tag" "  failed to unlock with clevis, passing through to real /sbin/cryptsetup"
        /sbin/cryptsetup "$@"
      else
        /usr/bin/logger -t "$logger_tag" "  succesfully unlocked with clevis device \"$2\""
      fi
    fi
else
    # Otherwise just pass all arguments directly to cryptsetup
    /usr/bin/logger -t "$logger_tag" " no luksOpen, passing through to real /sbin/cryptsetup"
    /sbin/cryptsetup "$@"
fi
