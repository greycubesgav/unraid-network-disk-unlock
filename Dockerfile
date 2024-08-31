FROM greycubesgav/slackware-docker-base:latest AS builder

# Set our prepended build artifact tag and build dir
ENV TAG='_GG' BUILD='-1'

RUN mkdir cryptsetup
WORKDIR /root/cryptsetup
# #RUN wget --no-check-certificate 'https://mirrors.slackware.com/slackware/slackware64-current/source/a/cryptsetup/cryptsetup-2.7.1.tar.xz'
# #RUN wget --no-check-certificate 'https://mirrors.slackware.com/slackware/slackware64-current/source/a/cryptsetup/cryptsetup.SlackBuild'
# RUN wget --no-check-certificate 'https://mirrors.edge.kernel.org/pub/linux/utils/cryptsetup/v2.6/cryptsetup-2.6.1.tar.xz'
COPY src/cryptsetup-2.6.1.tar.xz /root/cryptsetup
COPY src/cryptsetup.SlackBuild /root/cryptsetup
WORKDIR /root/cryptsetup/
RUN ./cryptsetup.SlackBuild
RUN ls -l /tmp
RUN installpkg /tmp/cryptsetup-*.txz

# Build JQ
# Required for the building of jose and clevis
WORKDIR /root
RUN wget --no-check-certificate  'https://slackbuilds.org/slackbuilds/15.0/system/jq.tar.gz'
RUN tar zxf jq.tar.gz
WORKDIR /root/jq
RUN wget --no-check-certificate 'https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-1.7.1.tar.gz'
RUN ./jq.SlackBuild
RUN installpkg /tmp/jq-*.tgz

# Build jose from custom slackware-build
# Install for clevis build
RUN echo y | slackpkg install infozip
RUN mkdir /root/jose
WORKDIR /root/jose
RUN wget --no-check-certificate 'https://github.com/greycubesgav/slackbuild-jose/archive/refs/heads/main.zip' -O jose-build.zip
RUN unzip jose-build.zip
WORKDIR /root/jose/slackbuild-jose-main/
RUN wget --no-check-certificate $(sed -n 's/DOWNLOAD="\(.*\)"/\1/p' *.info)
RUN ./jose.SlackBuild
RUN installpkg /tmp/jose-*.tgz

# Build luksmeta from custom slackware-build
# Install for clevis build
RUN mkdir /root/luksmeta
WORKDIR /root/luksmeta
RUN wget --no-check-certificate 'https://github.com/greycubesgav/slackbuild-luksmeta/archive/refs/heads/main.zip' -O luksmeta-build.zip
RUN unzip luksmeta-build.zip
WORKDIR /root/luksmeta/slackbuild-luksmeta-main/
RUN wget --no-check-certificate $(sed -n 's/DOWNLOAD="\(.*\)"/\1/p' *.info)
RUN ./luksmeta.SlackBuild
RUN installpkg /tmp/luksmeta-*.tgz

# # Build tpm2-tss from custom slackware-build
# # Install for tpm2-tools build
# #RUN echo y | slackpkg install infozip
# RUN mkdir /root/tpm2-tss
# WORKDIR /root/tpm2-tss
# RUN wget --no-check-certificate 'https://github.com/greycubesgav/slackbuild-tpm2-tss/archive/refs/heads/main.zip' -O tpm2-tss-build.zip
# RUN unzip tpm2-tss-build.zip
# WORKDIR /root/tpm2-tss/slackbuild-tpm2-tss-main
# RUN wget --no-check-certificate $(sed -n 's/DOWNLOAD="\(.*\)"/\1/p' *.info)
# RUN ./tpm2-tss.SlackBuild
# RUN installpkg /tmp/tpm2-tss-4.0.1-x86_64-GG_GG.tgz

# # Make and install tpm2-tss for tpm2-tools build for clevis build
# RUN mkdir /root/tpm2-tools
# WORKDIR /root/tpm2-tools
# RUN wget --no-check-certificate 'https://github.com/greycubesgav/slackbuild-tpm2-tools/archive/refs/heads/main.zip' -O tpm2-tools-build.zip
# RUN unzip tpm2-tools-build.zip
# WORKDIR /root/tpm2-tools/slackbuild-tpm2-tools-main
# RUN wget --no-check-certificate $(sed -n 's/DOWNLOAD="\(.*\)"/\1/p' *.info)
# RUN ./tpm2-tools.SlackBuild
# RUN installpkg /tmp/tpm2-tools-5.6-x86_64-GG_GG.tgz

# Build clevis from custom slackware-build
WORKDIR /root
RUN mkdir clevis
WORKDIR /root/clevis
RUN wget --no-check-certificate 'https://github.com/greycubesgav/slackbuild-clevis/archive/refs/heads/main.zip' -O clevis-build.zip
RUN unzip clevis-build.zip
WORKDIR /root/clevis/slackbuild-clevis-main/
RUN wget --no-check-certificate $(sed -n 's/DOWNLOAD="\(.*\)"/\1/p' *.info) && ls
RUN ./clevis.SlackBuild
RUN installpkg /tmp/clevis-*.tgz

# Copy into the docker image the clevis-unraid scripts
ARG PLG_VERSION=1.0.0
COPY network.disk.unlock/ /root/network.disk.unlock/
WORKDIR /root/network.disk.unlock/
RUN /sbin/makepkg -l y -c n "/tmp/unraid.network.disk.unlock-${PLG_VERSION}-noarch-$BUILD$TAG.txz"
RUN installpkg "/tmp/unraid.network.disk.unlock-${PLG_VERSION}-noarch-$BUILD$TAG.txz"

ENTRYPOINT [ "bash" ]

## Create a clean image with only the artifact
FROM scratch AS artifact
COPY --from=builder /tmp/clevis*.* /tmp/jose*.* /tmp/unraid.network.disk.unlock*.* ./
