FROM ghcr.io/linuxserver/baseimage-fedora:42 AS builder

COPY /patches /patches
ENV PATCH_VERSION=21 \
    HOME=/config

RUN \
  echo "**** build deps ****" && \
  dnf install -y \
    dnf-plugins-core \
    rpm-build && \
 dnf builddep -y \
    xorg-x11-server

RUN \
  echo "**** get and build xvfb ****" && \
  dnf download -y \
    --source xorg-x11-server-Xvfb && \
  rpm -ivh \
    xorg-x11-server-*.src.rpm && \
  cd /config/rpmbuild/SOURCES/ && \
  VERSION=$(echo xorg-server-*.tar.xz \
    | sed -e 's/^xorg-server-//' -e 's/\.tar\.xz$//') && \
  tar -xf xorg-server-*.tar.xz && \
  cd xorg-server-${VERSION} && \
  cp \
    /patches/${PATCH_VERSION}-xvfb-dri3.patch \
    patch.patch && \
  patch -p0 < patch.patch && \
  cd .. && \
  rm -f xorg-server-*.tar.xz && \
  tar -cJf \
    xorg-server-${VERSION}.tar.xz \
    xorg-server-${VERSION} && \
  rpmbuild -ba \
    /config/rpmbuild/SPECS/xorg-x11-server.spec && \
  rpm2cpio \
    /config/rpmbuild/RPMS/x86_64/xorg-x11-server-Xvfb-21.*.x86_64.rpm \
    | cpio -idmv && \
  mkdir -p /build-out/usr/bin && \
  mv usr/bin/Xvfb /build-out/usr/bin/


# runtime stage
FROM scratch
COPY --from=builder /build-out /
