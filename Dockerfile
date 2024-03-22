FROM vbatts/slackware:15.0
#FROM vbatts/slackware:current
#FROM andy5995/slackware:15.0

USER root
ENV USER=root

#RUN echo 'http://ftp.gwdg.de/pub/linux/slackware/slackware64-current/' > '/etc/slackpkg/mirrors'
#RUN echo 'https://mirrors.slackware.com/slackware/slackware64-current' > '/etc/slackpkg/mirrors'
#RUN rm -rf /root/.gnupg/

RUN echo y | slackpkg update

RUN echo y | slackpkg install lzlib

RUN echo y | slackpkg install \
      autoconf \
      autoconf-archive \
      automake \
      binutils \
      kernel-headers \
      pkg-tools \
      glibc \
      automake \
      autoconf \
      m4 \
      gcc \
      g++ \
      meson \
      ninja \
      ar \
      flex \
      pkg-config \
      cmake \
      libarchive \
      lz4 \
      libxml2 \
      nghttp2 \
      brotli \
      cyrus-sasl \
      jansson \
      elfutils \
      guile \
      gc \
      cryptsetup \
      curl \
      python3 \
      zlib \
      socat \
      linuxdoc-tools \
      keyutils \
      openssl \
      libxslt \
      openldap \
      libnsl \
      lvm2 \
      eudev \
      json-c  \
      make \
      libffi \
      libidn2 \
      libssh2 \
      ca-certificates

RUN echo y | slackpkg install \
      libgcrypt \
      libgpg-error \
      dcron \
      udisks2

RUN echo y | slackpkg install \
      openssh

# Set the SlackBuild tag
ENV TAG='_GG'
ENV BUILD='GG'

# Cryptsetup build
WORKDIR /root
RUN echo y | slackpkg install lvm2 \
 popt \
 pkg-config \
 json-c \
 libssh2 \
 libssh \
 argon2 \
 flex \
 libgpg-error \
 libgcrypt

RUN mkdir cryptsetup
WORKDIR /root/cryptsetup
RUN wget --no-check-certificate 'https://mirrors.slackware.com/slackware/slackware64-current/source/a/cryptsetup/cryptsetup-2.7.1.tar.xz'
RUN wget --no-check-certificate 'https://mirrors.slackware.com/slackware/slackware64-current/source/a/cryptsetup/cryptsetup.SlackBuild'
RUN chmod +x cryptsetup.SlackBuild
RUN ./cryptsetup.SlackBuild
RUN installpkg /tmp/cryptsetup-2.7.1-x86_64-GG.txz

# Build JQ
# Required for the building of jose and clevis
WORKDIR /root
RUN wget --no-check-certificate  'https://slackbuilds.org/slackbuilds/15.0/system/jq.tar.gz'
RUN tar zxf jq.tar.gz
WORKDIR /root/jq
RUN wget --no-check-certificate 'https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-1.7.1.tar.gz'
RUN ./jq.SlackBuild
RUN installpkg /tmp/jq-1.7.1-x86_64-GG_GG.tgz

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
RUN installpkg /tmp/jose-12-x86_64-GG_GG.tgz

# Build luksmeta from custom slackware-build
# Install for clevis build
RUN mkdir /root/luksmeta
WORKDIR /root/luksmeta
RUN wget --no-check-certificate 'https://github.com/greycubesgav/slackbuild-luksmeta/archive/refs/heads/main.zip' -O luksmeta-build.zip
RUN unzip luksmeta-build.zip
WORKDIR /root/luksmeta/slackbuild-luksmeta-main/
RUN wget --no-check-certificate $(sed -n 's/DOWNLOAD="\(.*\)"/\1/p' *.info)
RUN ./luksmeta.SlackBuild
RUN installpkg /tmp/luksmeta-9-x86_64-GG_GG.tgz

# Make and install tpm2-tss for tpm2-tools build
WORKDIR /root
RUN wget --no-check-certificate 'https://github.com/tpm2-software/tpm2-tss/releases/download/4.0.1/tpm2-tss-4.0.1.tar.gz'
RUN tar zxf tpm2-tss-4.0.1.tar.gz
WORKDIR /root/tpm2-tss-4.0.1
RUN ./configure --prefix=/usr
RUN make
RUN make install

# Make and Install tpm2-tools for clevis
WORKDIR /root
RUN wget --no-check-certificate 'https://github.com/tpm2-software/tpm2-tools/releases/download/5.6/tpm2-tools-5.6.tar.gz'
RUN tar zxf tpm2-tools-5.6.tar.gz
WORKDIR /root/tpm2-tools-5.6
RUN export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:${PKG_CONFIG_PATH}" && ./configure --prefix=/usr
RUN make && make install

# Build clevis from custom slackware-build
WORKDIR /root
RUN mkdir clevis
WORKDIR /root/clevis
RUN wget --no-check-certificate 'https://github.com/greycubesgav/slackbuild-clevis/archive/refs/heads/main.zip' -O clevis-build.zip
RUN unzip clevis-build.zip
WORKDIR /root/clevis/slackbuild-clevis-main/
RUN wget --no-check-certificate $(sed -n 's/DOWNLOAD="\(.*\)"/\1/p' *.info)
RUN ./clevis.SlackBuild


# Copy into the docker image the clevis-unraid scripts
COPY clevis.unraid/ /root/clevis.unraid/
WORKDIR /root/clevis.unraid/
RUN /sbin/makepkg -l y -c n "/tmp/clevis-unraid-01-noarch-$BUILD$TAG.txz"
RUN installpkg "/tmp/clevis-unraid-01-noarch-$BUILD$TAG.txz"

# Final artifact
# /tmp/clevis-20-x86_64-GG_GG.tgz


# # Build & install jose
# WORKDIR /root
# RUN wget --no-check-certificate 'https://github.com/latchset/jose/releases/download/v12/jose-12.tar.xz'
# RUN tar -Jxf jose-12.tar.xz
# RUN cd jose-12 && mkdir build && cd build && meson setup .. --prefix=/usr && ninja && ninja install

# # Build & Install luksmeta
# RUN wget --no-check-certificate 'https://github.com/latchset/luksmeta/releases/download/v9/luksmeta-9.tar.bz2'
# RUN tar jxf luksmeta-9.tar.bz2 && cd luksmeta-9 && ./configure --prefix=/usr && make && make install

# RUN wget --no-check-certificate  'https://slackbuilds.org/slackbuilds/15.0/system/jq.tar.gz'
# RUN tar zxf jq.tar.gz
# WORKDIR /root/jq
# RUN wget --no-check-certificate 'https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-1.7.1.tar.gz'
# RUN ./jq.SlackBuild
# RUN installpkg /tmp/jq-1.7.1-x86_64-1_SBo.tgz

# # Install tpm2-tss
# WORKDIR /root
# RUN wget --no-check-certificate 'https://github.com/tpm2-software/tpm2-tss/releases/download/4.0.1/tpm2-tss-4.0.1.tar.gz'
# RUN tar zxf tpm2-tss-4.0.1.tar.gz
# WORKDIR /root/tpm2-tss-4.0.1
# RUN ./configure --prefix=/usr
# RUN make
# RUN make install

# # Install tpm2-tools
# WORKDIR /root
# RUN wget --no-check-certificate 'https://github.com/tpm2-software/tpm2-tools/releases/download/5.6/tpm2-tools-5.6.tar.gz'
# RUN tar zxf tpm2-tools-5.6.tar.gz
# WORKDIR /root/tpm2-tools-5.6
# RUN export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:${PKG_CONFIG_PATH}" && ./configure --prefix=/usr
# RUN make && make install

# # Install clevis
# WORKDIR /root
# RUN wget --no-check-certificate  'https://github.com/latchset/clevis/releases/download/v20/clevis-20.tar.xz'
# RUN tar Jxvf clevis-20.tar.xz
# WORKDIR /root/clevis-20
# RUN mkdir build
# WORKDIR /root/clevis-20/build/
# RUN export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:${PKG_CONFIG_PATH}" && meson setup .. --prefix=/usr
# RUN ninja && ninja install


#RUN echo y | slackpkg upgrade slackpkg
#RUN echo y | slackpkg upgrade aaa_glibc-solibs

#Returns an error if there are no packages to upgrade
#RUN /bin/bash -c 'set -e; \
#    r=0; \
#    echo y | slackpkg upgrade-all || r=$?; \
#    if [ $r -ne 0 ] && [ $r -ne 20 ]; then \
#      exit $r; \
#    fi'

CMD ["/bin/bash","-l"]
