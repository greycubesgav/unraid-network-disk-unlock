#!/bin/bash

get_encrypted_disks() {
  input_file="$1"
  # Get a list of disks that have 'fstype' beginning with 'luks:'
  awk -F'=' '
/^\[(.*)\]/{section=$1; gsub(/[]["]/,"",section); next}
/^device=/{device=$2; gsub(/"/,"",device); next}
/^fsType="luks:/{fsType=$2; gsub(/"/,"",fsType);print section ";" device ";" fsType}
' "$input_file"
  ret=$?
  return $ret
}

disks_file='/usr/local/emhttp/state/disks.ini'

# Startup
echo -e "This script is part of the network.disk.unlock plugin for Unraid.
It intented to be used to setup the inital tang server url on your encrypted
luks disks and is meant to be ran when first setting your disks or when adding a
new encrypted disk."

# Checking what disks we have and if they are already setup with tang

echo '
██╗     ██╗   ██╗██╗  ██╗███████╗    ██████╗ ██╗███████╗██╗  ██╗███████╗
██║     ██║   ██║██║ ██╔╝██╔════╝    ██╔══██╗██║██╔════╝██║ ██╔╝██╔════╝
██║     ██║   ██║█████╔╝ ███████╗    ██║  ██║██║███████╗█████╔╝ ███████╗
██║     ██║   ██║██╔═██╗ ╚════██║    ██║  ██║██║╚════██║██╔═██╗ ╚════██║
███████╗╚██████╔╝██║  ██╗███████║    ██████╔╝██║███████║██║  ██╗███████║
╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═════╝ ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝
========================================================================='

# Try and get the list of luks encrypted disks
if ! luks_disks=$(get_encrypted_disks "$disks_file"); then
  echo "Error: failed to get a list of any encrypted disks from unraid." >&2
  echo "Have you setup any encrypted disks in Unraid yet?" >&2
  exit 2
fi

# Read through the list of encrypted disks, looking for any that don't have tang binds
echo "Checking the encrypted disks for existing tang server binds:"
devices_to_do=""
while read -r line; do
  if ! device=$(awk -F';' '{print $2}' 2>/dev/null <<< "$line"); then
    echo "Warning: failed to get device from disk line, was the line formatted correctly? line='$line'" >&2
    continue
  fi

  if ! tang_servers=$(clevis luks list -d "/dev/${device}1" 2>/dev/null ); then
    echo "Warning: error readling luks list for disk: ${device}1" >&2
    continue
  elif [ -z "$tang_servers" ]; then
    # We didn't find any tang servers for this disk
    echo "${device}1 <no tang binds>"
    devices_to_do="$device $devices_to_do"
    continue
  else
    #echo -e "device: ${device}1 already contains at least one tang server bind:\n${tang_servers}\nskipping ${device}1\n"
    sed -E "s/^.*/${device}1 slot \0/" <<< "$tang_servers"
    continue
  fi
done <<< "$luks_disks"

## Check if we have disks still to setup
# Test override
#devices_to_do='sde;'

if [ -n "$devices_to_do" ]; then

    echo '
████████╗ █████╗ ███╗   ██╗ ██████╗     ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗
╚══██╔══╝██╔══██╗████╗  ██║██╔════╝     ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗
   ██║   ███████║██╔██╗ ██║██║  ███╗    ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝
   ██║   ██╔══██║██║╚██╗██║██║   ██║    ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗
   ██║   ██║  ██║██║ ╚████║╚██████╔╝    ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝     ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝
============================================================================================='

    echo "Luks devices found that are missing tang server setup: $devices_to_do"
    # Get & test the tang server from the user
    #read -p "Enter your tang server url, e.g. http://tang.server:port > " tang_server
    tang_server='http://pi4-docker.greycubes.cloud:1234/'
    if ! curl -sf "${tang_server}/adv" >/dev/null; then
      echo "Error: Failed to connect to your supplied tang server's advertisement at: [${tang_server}/adv]" >&2
      echo "Please ensure your tang server is setup and reachable before proceeding to setup your disks."
      exit 1
    fi

    echo "Attempting to setup the tang binds....[$devices_to_do]"

    for device in $devices_to_do; do
        echo "Running:"  clevis luks bind -d "/dev/${device}1" tang "'{\"url\": \"${tang_server}\"}'"
        tang_json="{\"url\": \"${tang_server}\"}"
        echo -n 'Enter existing LUKS password: '
        # Connect the stdin from this script to the clevis subscript
        exec 0</dev/tty
        clevis luks bind -d "/dev/${device}1" -k - tang "$tang_json"
        ret=$?
        exec 0<&-
        if [ $ret -ne 0 ] ; then
            echo "Error: failed to setup tang server for disk: ${device}1" >&2
            exit 13
        else
            echo "Successfully setup tang server for disk: ${device}1"
        fi
    done <<< "$devices_to_do"
else
  echo ""
  echo "No luks encrypted devices in Unraid are missing tang server setup."
fi


echo '
██╗  ██╗███████╗██╗   ██╗    ███████╗██╗██╗     ███████╗
██║ ██╔╝██╔════╝╚██╗ ██╔╝    ██╔════╝██║██║     ██╔════╝
█████╔╝ █████╗   ╚████╔╝     █████╗  ██║██║     █████╗
██╔═██╗ ██╔══╝    ╚██╔╝      ██╔══╝  ██║██║     ██╔══╝
██║  ██╗███████╗   ██║       ██║     ██║███████╗███████╗
╚═╝  ╚═╝╚══════╝   ╚═╝       ╚═╝     ╚═╝╚══════╝╚══════╝
========================================================='

# Replace any existing keyfile that doesn't match our placeholder one
if [ -f '/root/keyfile' ] && cmp -s '/root/keyfile' <(echo 'network.disk.unlock.placeholder'); then
 echo "Placeholder keyfile already in place, skipping"
else
  echo "You have an existing keyfile in your root directory!"
  echo "While this file is in place, Unraid will use it to unlock your disks,"
  echo "and your encryption key will be stored beside your encrypted disks."
  read -p "Do you want to back it up and replace it with a placeholder (Recommended)? [y/n]:" -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\nProceeding..."
    if ! mv /root/keyfile /root/keyfile.backup; then
      echo 'Failed to back up existing keyfile! Aborting' >&2
      exit 12
    else
      echo "Old encryption key stored in '/root/keyfile.backup', ensure you have a backup, then delete this file!"
    fi

    if ! echo 'network.disk.unlock.placeholder' > /root/keyfile; then
      echo 'Failed to create placeholder keyfile! Aborting' >&2
      exit 13
    else
      echo "Placeholder keyfile successfully created in '/root/keyfile'"
    fi
  else
    echo -e "\nAborting..."
    exit 14
  fi
fi


echo '
██████╗  ██████╗ ███╗   ██╗███████╗
██╔══██╗██╔═══██╗████╗  ██║██╔════╝
██║  ██║██║   ██║██╔██╗ ██║█████╗
██║  ██║██║   ██║██║╚██╗██║██╔══╝
██████╔╝╚██████╔╝██║ ╚████║███████╗
╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝'
echo "Setup completed!"
echo ""
echo "Please reboot your server to start start using your tang server to unlock your disks!"
echo "Note: You do not need to run this script agains unless you add a new encrypted disk to Unraid"
