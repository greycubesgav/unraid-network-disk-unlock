#!/usr/bin/env bash

plugin_version="$1"
VERSION=${plugin_version:=0000.00.00}

# Script to update the plugin file with details of the latest built packages
plugin_tmpl_file=network.disk.unlock.plg.tmpl
plugin_file='/root/built.pkgs/network.disk.unlock.plg'

md5sum /root/built.pkgs/* > /root/built.pkgs/md5sums

# clevis_md5=$(grep clevis /root/built.pkgs/md5sums | awk '{print $1}')
# clevis_pkg=$(basename "$(grep clevis /root/built.pkgs/md5sums | awk '{print $2}')" )

# jose_md5=$(grep clevis /root/built.pkgs/md5sums | awk '{print $1}')
# jose_pkg=$(basename "$(grep jose /root/built.pkgs/md5sums | awk '{print $2}')" )

plugin_md5=$(grep unraid.network.disk.unlock /root/built.pkgs/md5sums | awk '{print $1}')
plugin_pkg=$(basename "$(grep unraid.network.disk.unlock /root/built.pkgs/md5sums| awk '{print $2}')" )

# Extract the version from the package name
VERSION=$(echo "$plugin_pkg" | sed 's/.*-\([0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}\)-.*/\1/' )

github_url="https://github.com/greycubesgav/unraid-network-disk-unlock/releases/download/${VERSION}"

echo "Updating $plugin_file..."

# # Dependency #1 - clevis
# echo "clevis_md5: [$clevis_md5]"
# awk -v md5="$clevis_md5" '/<!ENTITY dep1_md5/ {gsub(/"[^"]*"/, "\"" md5 "\"")}1' "$plugin_file" > tmp_plg.txt
# cat tmp_plg.txt > "$plugin_file"

# echo "clevis_pkg: [$clevis_pkg]"
# awk -v pkg="$clevis_pkg" '/<!ENTITY dep1_pkg/ {gsub(/"[^"]*"/, "\"" pkg "\"")}1' "$plugin_file" > tmp_plg.txt
# cat tmp_plg.txt > "$plugin_file"

# # Dependency #2 - jose
# echo "jose_md5: [$jose_md5]"
# awk -v md5="$jose_md5" '/<!ENTITY dep2_md5/ {gsub(/"[^"]*"/, "\"" md5 "\"")}1' "$plugin_file" > tmp_plg.txt
# cat tmp_plg.txt > "$plugin_file"

# echo "jose_pkg: [$jose_pkg]"
# awk -v pkg="$jose_pkg" '/<!ENTITY dep2_pkg/ {gsub(/"[^"]*"/, "\"" pkg "\"")}1' "$plugin_file" > tmp_plg.txt
# cat tmp_plg.txt > "$plugin_file"

# Plugin
echo "plugin_md5: [$plugin_md5]"
awk -v md5="$plugin_md5" '/<!ENTITY src_md5/ {gsub(/"[^"]*"/, "\"" md5 "\"")}1' "$plugin_tmpl_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

echo "plugin_pkg: [$plugin_pkg]"
awk -v pkg="$plugin_pkg" '/<!ENTITY src_pkg/ {gsub(/"[^"]*"/, "\"" pkg "\"")}1' "$plugin_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

echo "plugin_version: [$VERSION]"
awk -v ver="$VERSION" '/<!ENTITY version/ {gsub(/"[^"]*"/, "\"" ver "\"")}1' "$plugin_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

# Update the github url
echo "github_url: [$github_url]"
awk -v url="$github_url" '/<!ENTITY gitURL/ {gsub(/"[^"]*"/, "\"" url "\"")}1' "$plugin_file" > tmp_plg.txt
mv tmp_plg.txt "$plugin_file"

cd /root/built.pkgs/
rm -f md5sums
md5sum ./* > md5sums