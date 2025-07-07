FROM ghcr.io/linuxserver/baseimage-ubuntu:noble AS builder

COPY /patches /patches
ENV PATCH_VERSION=21 \
    HOME=/config

RUN \
  echo "**** build deps ****" && \
  apt-get update && \
  apt-get install -y \
    devscripts \
    dpkg-dev && \
  apt-get build-dep -y \
    xorg-server 

RUN \
  echo "**** get and build xvfb ****" && \
  apt-get source xorg-server && \
  cd xorg-server-* && \
  cp \
    /patches/${PATCH_VERSION}-xvfb-dri3.patch \
    patch.patch && \
  patch -p0 < patch.patch && \
  awk ' \
    { print } \
    /include \/usr\/share\/dpkg\/architecture.mk/ { \
      print ""; \
      print "GLAMOR_DEP_LIBS := $(shell pkg-config --libs gbm epoxy libdrm)"; \
      print "GLAMOR_DEP_CFLAGS := $(shell pkg-config --cflags gbm epoxy libdrm)"; \
      print "export DEB_LDFLAGS_PREPEND ?= $(GLAMOR_DEP_LIBS)"; \
      print "export DEB_CFLAGS_PREPEND ?= $(GLAMOR_DEP_CFLAGS)"; \
    } \
  ' debian/rules > debian/rules.tmp && mv debian/rules.tmp debian/rules && \
  debuild -us -uc -b && \
  mkdir -p /build-out/usr/bin && \
  mv debian/xvfb/usr/bin/Xvfb /build-out/usr/bin/


# runtime stage
FROM scratch
COPY --from=builder /build-out /
