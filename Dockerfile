ARG DOCKER_FULL_BASE_IMAGE_NAME=greycubesgav/slackware-docker-base:aclemons-current
FROM ${DOCKER_FULL_BASE_IMAGE_NAME} AS builder

# Set our prepended build artifact tag and build dir
ARG UNRAID_VERSION='v7.x.x' BUILD=1 TAG='_GG' VERSION=1.0.0 ARC=x86_64

# #-------------------
# # Jose build
# #-------------------
# # Provides: jose
# # Install the custom built jose binary package by greycubes
# COPY src/pkgs/jose-12-x86_64-*_unraid-${UNRAID_VERSION}_GG.tgz /tmp/
# RUN installpkg /tmp/jose-*.tgz

# #-------------------
# # Cryptsetup build
# #-------------------
# # Provides: cryptsetup
# # Remove the default slackware cryptsetup in this image (2.7.1)
# RUN removepkg cryptsetup
# # Copy the 2.6.1 cryptsetup source files (current version for Unraid 6.x.x & 7.x.x) into the container
# # We're using the slackware 'current' build files for this build
# COPY src/cryptsetup/src/cryptsetup-2.6.1.tar.xz src/cryptsetup/current/* /root/cryptsetup/
# WORKDIR /root/cryptsetup/
# RUN ./cryptsetup.SlackBuild
# RUN installpkg /tmp/cryptsetup-*.txz

# #-------------------
# # Luksmeta build
# #-------------------
# # Build luksmeta from custom slackware-build
# # Requires: cryptsetup
# # Provides: luksmeta
# COPY src/slackbuild-luksmeta-main/* /root/luksmeta/
# WORKDIR /root/luksmeta
# RUN ./luksmeta.SlackBuild
# RUN installpkg /tmp/luksmeta-*.tgz

# # # Build tpm2-tss from custom slackware-build
# # # Install for tpm2-tools build
# # #RUN echo y | slackpkg install infozip
# # RUN mkdir /root/tpm2-tss
# # WORKDIR /root/tpm2-tss
# # RUN wget --no-check-certificate 'https://github.com/greycubesgav/slackbuild-tpm2-tss/archive/refs/heads/main.zip' -O tpm2-tss-build.zip
# # RUN unzip tpm2-tss-build.zip
# # WORKDIR /root/tpm2-tss/slackbuild-tpm2-tss-main
# # RUN wget --no-check-certificate $(sed -n 's/DOWNLOAD="\(.*\)"/\1/p' *.info)
# # RUN ./tpm2-tss.SlackBuild
# # RUN installpkg /tmp/tpm2-tss-4.0.1-x86_64-GG_GG.tgz

# # # Make and install tpm2-tss for tpm2-tools build for clevis build
# # RUN mkdir /root/tpm2-tools
# # WORKDIR /root/tpm2-tools
# # RUN wget --no-check-certificate 'https://github.com/greycubesgav/slackbuild-tpm2-tools/archive/refs/heads/main.zip' -O tpm2-tools-build.zip
# # RUN unzip tpm2-tools-build.zip
# # WORKDIR /root/tpm2-tools/slackbuild-tpm2-tools-main
# # RUN wget --no-check-certificate $(sed -n 's/DOWNLOAD="\(.*\)"/\1/p' *.info)
# # RUN ./tpm2-tools.SlackBuild
# # RUN installpkg /tmp/tpm2-tools-5.6-x86_64-GG_GG.tgz

# #-------------------
# # Clevis build
# #-------------------
# # Build clevis package from custom slackware-build setup
# # Final clevis package file is required for this plugin install
# # Requires: luksmeta, jose
# # Provides: clevis
# COPY src/slackbuild-clevis-main/* /root/clevis/
# WORKDIR /root/clevis
# RUN ./clevis.SlackBuild
# RUN installpkg /tmp/clevis-*.tgz


#--------------------------------------------------------------------------------------------
# Copy over all the required binary packages into the container, for inclusion in the plugin


#------------------------------------------------
# unraid-network-disk-unlock build
#------------------------------------------------
# Part 1 - Build the unraid-network-disk-unlock install plugin
  # Copy into the docker image the clevis-unraid scripts
COPY src/ /root/src/
WORKDIR /root/src/network.disk.unlock/
RUN mkdir '/root/built.pkgs/' && /sbin/makepkg -l y -c n "/root/built.pkgs/unraid.network.disk.unlock-${VERSION}-${ARC}${TAG}-${BUILD}.txz"
# Part 2 - Create the plugin xml file
# Create the plugin xml file
WORKDIR /root/src/
RUN ./network.disk.unlock.plg.tmpl-update.sh

#ENTRYPOINT [ "bash" ]

## Create a clean image with only the artifact
FROM scratch AS artifact
COPY --from=builder /root/built.pkgs/*network.disk.unlock*.* ./
