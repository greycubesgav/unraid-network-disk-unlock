#!/bin/bash

get_encrypted_disks() {
  input_file="$1"
  # Get a list of disks that have 'fstype' beginning with 'luks:'
  awk -F'=' '
/^\[(.*)\]/{section=$1; gsub(/[]["]/,"",section); next}
/^device=/{device=$2; gsub(/"/,"",device); next}
/^deviceSb=/{deviceSb=$2; gsub(/"/,"",deviceSb); gsub(/^mapper\//,"",deviceSb); next}
/^fsType="luks:/{fsType=$2; gsub(/"/,"",fsType);print section ";" device ";" fsType ";" deviceSb}
' "$input_file"
  ret=$?
  return $ret
}

disks_file='/usr/local/emhttp/state/disks.ini'
tang_server_config='/boot/config/plugins/network.disk.unlock/tang_server.cfg'

# Check for root privileges - use effective uid for most accurate result
if [ "$(id -u)" -ne 0 ]; then
  echo 'Error: This script must be run as root' >&2
  exit 99
fi

# Startup
echo -e "This script is part of the network.disk.unlock plugin for Unraid.
It intented to be used to setup the inital tang server url on your encrypted
luks disks and is meant to be ran when first setting your disks or when adding a
new encrypted disk."

read -p 'Do do you want to proceed with setting up your encrypted disks? [y/N]: ' -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "Aborting..."
  exit 98
fi

# Checking what disks we have and if they are already setup with tang

echo '

████████╗ █████╗ ███╗   ██╗ ██████╗     ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗
╚══██╔══╝██╔══██╗████╗  ██║██╔════╝     ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗
   ██║   ███████║██╔██╗ ██║██║  ███╗    ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝
   ██║   ██╔══██║██║╚██╗██║██║   ██║    ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗
   ██║   ██║  ██║██║ ╚████║╚██████╔╝    ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝     ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝
============================================================================================='

# Get & test the tang server from the user
tang_server=""
new_tang_server=""
# Read the tang server from the config file if it exists
if [ -f "$tang_server_config" ]; then
  tang_server=$(<"$tang_server_config")
  echo "Found existing tang server url in config file: $tang_server"
fi

while true; do
  if [ -z "$tang_server" ]; then
    read -r -p 'Enter your tang server url, e.g. http://tang.server:port > ' tang_server
    # Strip of any trailing /adv from the tang server
    tang_server=$(sed 's/\/adv$//' <<< "$tang_server")
    new_tang_server=1
  fi

  if curl -sf "${tang_server}/adv" >/dev/null; then
    echo "Successfully connected to tang server at: ${tang_server}"
    break
  else
    echo "Error: Failed to connect to tang server at: [${tang_server}/adv]" >&2
    echo 'Is the server url correct? Is Tang running? Does the server have the correct firewall rules?' >&2
    tang_server=""
  fi
done

# If the user has entered a new tang server, update the config file
if [ -n "$new_tang_server" ]; then
  echo "Updating the config file with the new tang server url: $tang_server"
  echo "$tang_server" > "$tang_server_config" || {
    echo "Warning: failed to write tang server url to config file: $tang_server_config, Permissions issue?"
    echo "Continuing.."
  }
fi


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
  echo " Please encrypt your disks before running this script" >&2
  echo " See: https://docs.unraid.net/unraid-os/manual/security/data-encryption/" >&2
  exit 2
fi

# Read through the list of encrypted disks, looking for any that don't have tang binds
echo "Checking the encrypted disks for existing tang server binds:"
echo -e "Note: this may take some time if disks are sleeping...\n"
devices_to_do=""
while read -r line; do
  #line='disk2;sdd;luks:xfs;md2p1'
  if ! device=$(awk -F';' '{if ($4=="") exit 1; print $4}' 2>/dev/null <<< "$line"); then
    echo "Warning: failed to get device from disk line, was the line formatted correctly? line='$line'" >&2
    continue
  fi
  device="/dev/${device}"
  if [ ! -b "${device}" ]; then
    echo "Warning: Unraid configured device [${device}] does not exist, has the device been removed? Skipping device.." >&2
    continue
    # echo "Warning: device [${device}] does not exist, trying to find associated raid device" >&2
    # if ! device=$(awk -F';' '{if ($4=="") exit 1; print $4}' 2>/dev/null <<< "$line"); then
    #   echo "Warning: failed to get raid device from disk line, was the line formatted correctly, not a raid disk? line='$line'" >&2
    #   continue
    # fi
    # echo "awk ${device}"
    # device="/dev/${device}"
    # echo "${device}"
    # if [ ! -b "${device}" ]; then
    #   echo "Warning: raid device [${device}] does not exist either, skipping entry" >&2
    #   continue
    # fi
  fi
  echo -n "${device}: "
  if ! tang_servers=$(clevis luks list -d "${device}" 2>/dev/null ); then
    echo "Warning: issue readling luks list for device [${device}], disk not encrypted?" >&2
    continue
  else
    if ! tang_servers=$(echo "$tang_servers" | grep 'tang'); then
      # We didn't find any tang servers for this disk
      echo "<no tang binds, adding to list>"
      devices_to_do="$device $devices_to_do"
      continue
    else
      echo -e "already contains at least one tang server bind:\n├─ entry ${tang_servers}\n└─ skipping device\n"
      #sed -E "s/^.*/${device}1 slot \0/" <<< "$tang_servers"
      continue
    fi
  fi
done <<< "$luks_disks"

## Check if we have disks still to setup
# Test override
#devices_to_do='sde;'

if [ -n "$devices_to_do" ]; then
    echo "You will be prompted to enter your existing disk encryption password for each disk"
    echo "Please ensure you have your disk encryption password ready before proceeding"
    echo "Note: after entered the password, the script will pause for a few seconds while the"
    echo "tang server is setup this is normal, please wait for the script to continue"
    echo ""

    echo "Setting up the tang binds for devices [$devices_to_do]"

    for device in $devices_to_do; do
        echo "Adding luks tang binding for: '${device}' tang \"'{\"url\": \"${tang_server}\"}'\""
        #  clevis luks bind -d "${device}" tang "'{\"url\": \"${tang_server}\"}'"
        tang_json="{\"url\": \"${tang_server}\"}"
        echo  'Enter your existing disk encryption password <press enter then wait a few seconds!>: '
        # Connect the stdin from this script to the clevis subscript
        exec 0</dev/tty
        clevis luks bind -d "${device}" -k - tang "$tang_json"
        ret=$?
        exec 0<&-
        if [ $ret -ne 0 ] ; then
            echo "Error: failed to setup tang server for disk: ${device}, aborting setup procedure" >&2
            exit 13
        else
            echo "Successfully setup tang server for disk: ${device}"
        fi
    done <<< "$devices_to_do"



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
    echo "You have an existing [/root/keyfile] which does not match this plugin's placeholder keyfile."
    echo "While this plaintext file is in place your array encryption key is vulnerable to snooping."
    echo "Please backup this keyfile before proceeding."
    read -p 'Do do you have a backup of your array encryption keyfile? [y/N]: ' -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo -e "\nProceeding...\n"
      backup_file="/root/keyfile.$(date '+%Y-%m-%d_%H-%M-%S').backup"
      if ! mv -n /root/keyfile "${backup_file}"; then
        echo 'Failed to back up existing keyfile! Aborting' >&2
        exit 12
      else
        echo "Old encryption key stored in '${backup_file}', ensure you have a backup before deleting this file!"
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

else
  echo "No luks encrypted devices in Unraid are missing tang server setup." >&2
  echo "Nothing to do, exiting..." >&2
fi
