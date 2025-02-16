#!//usr/bin/env bash
# Script to replace the base /usr/sbin/cryptsetup symlink with the shim to intercept luksOpen commands

pid="$$"
log_name='network.disk.unlock.plugin.install'
logger_tag="${log_name}[${pid}]"
notify_event='Plugin - network.disk.unlock'
plugin_loc='/usr/local/emhttp/plugins/network.disk.unlock'
shim_loc="${plugin_loc}/cryptsetup-shim.sh"
pkgs_loc="${plugin_loc}/pkgs"

# notify [-e "event"] [-s "subject"] [-d "description"] [-i "normal|warning|alert"] [-m "message"]
notify_loc='/usr/local/emhttp/webGui/scripts/notify'
alert() {
  #        logger_tag                                 event                          title                      message                                        level
  # alert 'network.disk.unlock.plugin.install[1234]' 'Plugin - network.disk.unlock' 'Issue installing package' 'Failed to install package $package, aborting!' "normal|warning|alert"
  local logger_tag="$1"
  local event="$2"
  local title="$3"
  local message="$4"
  local level="$5"
  # We have an alert to output a number of places
  echo ">> ${logger_tag}: ${title} - ${message}" >&2
  /usr/bin/logger -t "${logger_tag}" "${title} - ${message}"
  if [ -n "$level" ]; then
    #echo $notify_loc -e "${event}" -s "$title" -d "$message" -i "$level"
    $notify_loc -e "${event}" -s "$title" -d "$message" -i "$level"
  fi
}

#-----------------------------------------------------------------------------------------------------------------
# Start of install script
#-----------------------------------------------------------------------------------------------------------------
# Check for root privileges - use effective uid for most accurate result
if [ "$(id -u)" -ne 0 ]; then
  alert "$logger_tag" "$notify_event" \
    'Permission denied' \
    'This script must be run as root' \
  echo " ${logger_tag}: ${title} - ${message}" >&2
  exit 99
fi

#-----------------------------------------------------------------------------------------------------------------
# Unraid Version Check
#-----------------------------------------------------------------------------------------------------------------
# Workout what version of unraid we are
if [ -f '/lib64/libcrypto.so.1.1' ]; then
  pkgs_match='unraid-v6'
elif [ -f '/lib64/libcrypto.so.3' ]; then
  pkgs_match='unraid-v7'
else
  alert "$logger_tag" "$notify_event" \
    'Issue installing plugin' \
    "Failed to identify compatible version of libcrypto, aborting plugin install. Current libcrypto version appears to be : ($(ls /lib64/libcrypto\.*)). Does this plugin need updated?" \
    'warning'
  exit 1
fi

#-------------------------------------------------------------------------------------------------------
# Install the plugin dependencies
#-------------------------------------------------------------------------------------------------------
# Enable extended globbing
shopt -s extglob
# Find matching packages
pkg_files=("$pkgs_loc"/*_"${pkgs_match}".*.t*)
# Check if we found any packages
if [ -e "${pkg_files[0]}" ]; then
  for package in "${pkg_files[@]}"; do
    echo "> ${logger_tag}: Installing dependency: [$package]"
    if ! /sbin/upgradepkg --install-new --reinstall "$package"; then
      alert "$logger_tag" "$notify_event" \
        'Issue installing dependency package' \
        "Failed to install package [$package], aborting plugin install!" \
        'warning'
      exit 2
    fi
  done
else
  alert "$logger_tag" "$notify_event" \
    'Issue installing dependency packages' \
    "No dependency packages found at: \"$pkgs_loc/*_${pkgs_match}.*.t*\", aborting plugin install!" \
    'warning'
  exit 3
fi
# Disable extended globbing
shopt -u extglob

#-------------------------------------------------------------------------------------------------------
# Setup the symlinks
#-------------------------------------------------------------------------------------------------------
echo "> ${logger_tag}: Checking for cryptsetup symlink"
# Check if /usr/sbin/cryptsetup is a symlink
if [ ! -L /usr/sbin/cryptsetup ]; then
  alert "$logger_tag" "$notify_event" \
    'Issue setting up cryptsetup shim' \
    '[/usr/sbin/cryptsetup] is not a symlink, aborting plugin install!' \
    'warning'
  exit 11
fi

echo "> ${logger_tag}: Checking shim script is executable"
# Check the source script is executable
if [ ! -x "$shim_loc" ]; then
  alert "$logger_tag" "$notify_event" \
    'Issue setting up cryptsetup shim' \
    "[${shim_loc}] file is not executable, aborting plugin install!" \
    'warning'
  exit 12
fi

# Replace the existing cryptsetup symlink with our shim
#ln -s -f "$shim_loc" /usr/sbin/cryptsetup
#if [ $? -ne 0 ]; then
echo "> ${logger_tag}: Replacing /usr/sbin/cryptsetup symlink with new shim"
if ! ln -s -f "$shim_loc" /usr/sbin/cryptsetup; then
  alert "$logger_tag" "$notify_event" \
    'Issue setting up cryptsetup shim' \
    'Failed to replace [/usr/sbin/cryptsetup] symlink, aborting plugin install!' \
    'warning'
  exit 13
fi

# Temporary
# Overwrite /usr/bin/clevis-luks-unlock with patched version that allows -o options to be based through clevis
echo "> ${logger_tag}: Replacing /usr/bin/clevis-luks-unlock with patched version symlink"
if ! ln -fs /usr/local/emhttp/plugins/network.disk.unlock/clevis-luks-unlock /usr/bin/clevis-luks-unlock; then
  alert "$logger_tag" "$notify_event" \
    'Issue setting up cryptsetup shim' \
    'Failed to replace [/usr/bin/clevis-luks-unlock] with patched symlink, aborting plugin install!' \
    'warning'
  exit 14
fi

#-------------------------------------------------------------------------------------------------------
# Setup the placeholder keyfile
#-------------------------------------------------------------------------------------------------------
echo "> ${logger_tag}: Checking for placeholder keyfile"
# Create an placeholder key file to allow unraid to initiate the disk decryption on start
if [ -f /root/keyfile ] && ! cmp -s /root/keyfile <(echo 'network.disk.unlock.placeholder'); then
  alert "$logger_tag" "$notify_event" \
    'Issue setting up placeholder keyfile' \
    'The current [/root/keyfile] file is not a known placeholder. Your array local encryption key may still be vulnerable. Please run the plugin setup script: [/usr/local/emhttp/plugins/network.disk.unlock/network.disk.unlock.setup.sh]' \
    'warning'
else
  echo "> ${logger_tag}: Creating placeholder keyfile to allow auto decryption"
  if ! /usr/bin/install -m 0600 -o root -g root /dev/null /root/keyfile; then
    /usr/bin/logger -t "$logger_tag" 'Failed to create placeholder /root/keyfile aborting'
    exit 15
  fi
  if ! echo 'network.disk.unlock.placeholder' > /root/keyfile; then
    /usr/bin/logger -t "$logger_tag" 'Failed to write to placeholder /root/keyfile aborting'
    exit 16
  fi
fi

echo "> ${logger_tag}: Plugin successfully installed"
/usr/bin/logger -t "$logger_tag" 'Plugin successfully installed'
