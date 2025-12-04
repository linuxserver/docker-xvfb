FROM ghcr.io/linuxserver/baseimage-arch:latest AS builder

COPY /patches /patches
ENV PATCH_VERSION=21 \
    XORG_VERSION=21.1.20 \
    HOME=/config 

RUN \
  echo "**** build deps ****" && \
  pacman -Sy --noconfirm \
    base-devel \
    devtools \
    git \
    libepoxy \
    libpciaccess \
    libunwind \
    libx11 \
    libxaw \
    libxcvt \
    libxfont2 \
    libxi \
    libxkbfile \
    libxmu \
    libxrender \
    libxres \
    libxshmfence \
    libxtst \
    libxv \
    mesa \
    mesa-libgl \
    meson \
    patch \
    pixman \
    systemd \
    xcb-util \
    xcb-util-image \
    xcb-util-keysyms \
    xcb-util-renderutil \
    xcb-util-wm \
    xorg-font-util \
    xorgproto \
    xorg-util-macros \
    xorg-xkbcomp \
    xtrans 

RUN \
  echo "**** get and build xorg ****" && \
  curl -o \
    /tmp/xorg.tar.gz -L \
    "https://www.x.org/releases/individual/xserver/xorg-server-${XORG_VERSION}.tar.gz" && \
  cd /tmp && \
  tar xf xorg.tar.gz && \
  cd xorg-* && \
  cp \
    /patches/${PATCH_VERSION}-xvfb-dri3.patch \
    patch.patch && \
  patch -p1 < patch.patch && \
  export CFLAGS=${CFLAGS/-fno-plt} && \
  export CXXFLAGS=${CXXFLAGS/-fno-plt} && \
  export LDFLAGS=${LDFLAGS/-Wl,-z,now} && \
  arch-meson  build \
    -D ipv6=true \
    -D xvfb=true \
    -D xnest=true \
    -D xcsecurity=true \
    -D xorg=true \
    -D xephyr=true \
    -D glamor=true \
    -D udev=true \
    -D dtrace=false \
    -D systemd_logind=true \
    -D suid_wrapper=true \
    -D linux_acpi=false \
    -D xkb_dir=/usr/share/X11/xkb \
    -D xkb_output_dir=/var/lib/xkb \
    -D libunwind=true && \
  ninja -C build && \
  ninja -C build install && \
  mkdir -p /build-out/usr/bin && \
  mv /usr/bin/Xvfb /build-out/usr/bin/

# runtime stage
FROM scratch
COPY --from=builder /build-out /
