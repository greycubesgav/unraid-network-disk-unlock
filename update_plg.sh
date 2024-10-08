#!/usr/bin/env bash

plugin_version="$1"
VERSION=${plugin_version:=0000.00.00}

# Script to update the plugin file with details of the latest built packages
plugin_tmpl_file=network.disk.unlock.plg.tmpl
plugin_file=network.disk.unlock.plg
github_url="https://github.com/greycubesgav/unraid-network-disk-unlock/releases/download/${VERSION}/"


cd pkgs || exit 1
md5sum clevis-*.tgz jose-*.tgz unraid.network.disk.unlock-*.txz > md5sums
cd ..

clevis_md5=$(grep clevis ./pkgs/md5sums | awk '{print $1}')
clevis_pkg=$(grep clevis ./pkgs/md5sums | awk '{print $2}')
jose_md5=$(grep jose ./pkgs/md5sums | awk '{print $1}')
jose_pkg=$(grep jose ./pkgs/md5sums | awk '{print $2}')
plugin_md5=$(grep unraid.network.disk.unlock ./pkgs/md5sums | awk '{print $1}')
plugin_pkg=$(grep unraid.network.disk.unlock ./pkgs/md5sums | awk '{print $2}')

echo "Updating $plugin_file..."
echo "plugin_pkg: [$plugin_pkg]"

awk -v md5="$plugin_md5" '/<!ENTITY src_md5/ {gsub(/"[^"]*"/, "\"" md5 "\"")}1' "$plugin_tmpl_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

awk -v md5="$clevis_md5" '/<!ENTITY dep1_md5/ {gsub(/"[^"]*"/, "\"" md5 "\"")}1' "$plugin_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

awk -v md5="$jose_md5" '/<!ENTITY dep2_md5/ {gsub(/"[^"]*"/, "\"" md5 "\"")}1' "$plugin_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

awk -v pkg="$plugin_pkg" '/<!ENTITY src_pkg/ {gsub(/"[^"]*"/, "\"" pkg "\"")}1' "$plugin_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

awk -v pkg="$clevis_pkg" '/<!ENTITY dep1_pkg/ {gsub(/"[^"]*"/, "\"" pkg "\"")}1' "$plugin_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

awk -v pkg="$jose_pkg" '/<!ENTITY dep2_pkg/ {gsub(/"[^"]*"/, "\"" pkg "\"")}1' "$plugin_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

awk -v ver="$VERSION" '/<!ENTITY version/ {gsub(/"[^"]*"/, "\"" ver "\"")}1' "$plugin_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

awk -v url="$github_url" '/<!ENTITY gitURL/ {gsub(/"[^"]*"/, "\"" url "\"")}1' "$plugin_file" > tmp_plg.txt
cat tmp_plg.txt > "$plugin_file"

rm tmp_plg.txt
