# Unraid Network Disk Unlocker

This repository holds the code to build my Unraid Network Disk Unlocker plugin.

Network Disk Unlocker allows [Unraid](https://unraid.net/) to decrypt disks using [clevis](https://github.com/latchset/clevis) bound to a remote [Tang server](https://github.com/latchset/tang). This allows for fully secure array unlocking without the need for a keyfile on the server or manual intervention to start the arrray.

<p align="center">
  <img src="src/screenshot01.png" width="800" title="network_disk_unlocker_screenshot">
</p>

# Build Instructions

Running `./build_artifact.sh` will build a Slackware 15 base docker image and proceed to build all the required slackware packages build the final 3 artifacts needed for the plugin:

1. jose-12-x86_64-GG_GG.tgz
1. clevis-20-x86_64-GG_GG.tgz
1. unraid.network.disk.unlock-01-noarch-GG_GG.txz

These packages will be copied out of the file image and placed in the ./packages directory.

See the my Unraid Templates repository for details of how to carry out the requisite setup on your encrypted array disks to allow the plugin to unlock the disks automatically using a remote tang server.
