#!/usr/bin/env bash

# Script to update the plugin file with details of the latest built packages
plugin_tmpl_file=network.disk.unlock.plg.tmpl
plugin_file='/root/built.pkgs/network.disk.unlock.plg'
plugin_md5=$(md5sum /root/built.pkgs/unraid.network.disk.unlock-*.txz | awk '{print $1}')
plugin_pkg=$(basename "$(find /root/built.pkgs/ -type f -name 'unraid.network.disk.unlock-*.txz'| head -1)" )

# Extract the version from the package name
plugin_version=$(echo "$plugin_pkg" | grep -Po '(\d{4}\.\d{2}\.\d{2})-[^-]+-(\d+)(?=_)' | sed -E 's|-[^-]+-|.|' )

echo "Updating [$plugin_file]..."

# Plugin
echo "plugin_md5: [$plugin_md5]"
awk -v md5="$plugin_md5" '/<!ENTITY src_md5/ {gsub(/"[^"]*"/, "\"" md5 "\"")}1' "$plugin_tmpl_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

echo "plugin_pkg: [$plugin_pkg]"
awk -v pkg="$plugin_pkg" '/<!ENTITY src_pkg/ {gsub(/"[^"]*"/, "\"" pkg "\"")}1' "$plugin_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

echo "plugin_version: [$plugin_version]"
awk -v ver="$plugin_version" '/<!ENTITY version/ {gsub(/"[^"]*"/, "\"" ver "\"")}1' "$plugin_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

# Update the plugin file
mv tmp_plg.txt "$plugin_file"

# Setup .md5 files for all artifacts
cd /root/built.pkgs/ || exit 2
find . -type f -not -name "." -iname '*.*' -exec sh -c 'md5sum "$1" > "$1.md5"' sh {} \;
