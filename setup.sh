#!/bin/sh

set -e

scheme="$1"

retry() {
  retries=$1
  shift

  count=0
  until "$@"; do
    exit=$?
    wait="$(echo "2^$count" | bc)"
    count="$(echo "$count + 1" | bc)"
    if [ "$count" -lt "$retries" ]; then
      echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
      sleep "$wait"
    else
      echo "Retry $count/$retries exited $exit, no more retries left."
      return "$exit"
    fi
  done
}

echo "==> Install system packages"
apk --no-cache add \
  bash \
  curl \
  fontconfig \
  ghostscript \
  gnupg \
  git \
  graphviz \
  make \
  openjdk17-jre-headless \
  perl \
  py-pygments \
  python3 \
  tar \
  ttf-freefont \
  wget \
  xz

# Dependencies needed by latexindent
apk --no-cache add \
  perl-unicode-linebreak \
  perl-yaml-tiny
apk --no-cache add \
  --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
  perl-file-homedir

echo "==> Install TeXLive"
mkdir -p /tmp/install-tl
cd /tmp/install-tl
MIRROR_URL="$(curl -w "%{redirect_url}" -o /dev/null -s http://mirror.ctan.org/)"
curl -OL "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz"
curl -OL "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz.sha512"
curl -OL "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz.sha512.asc"
gpg --import /texlive_pgp_keys.asc
gpg --verify ./install-tl-unx.tar.gz.sha512.asc ./install-tl-unx.tar.gz.sha512
sha512sum -c ./install-tl-unx.tar.gz.sha512
mkdir -p /tmp/install-tl/installer
tar --strip-components 1 -zxf /tmp/install-tl/install-tl-unx.tar.gz -C /tmp/install-tl/installer
retry 3 /tmp/install-tl/installer/install-tl -scheme "scheme-$scheme" -profile=/texlive.profile

# Install additional packages for non full scheme
if [ "$scheme" != "full" ]; then
  tlmgr install \
    collection-fontsrecommended \
    collection-fontutils \
    biber \
    biblatex \
    latexmk \
    texliveonfly
fi

# System font configuration for XeTeX and LuaTeX
# Ref: https://www.tug.org/texlive/doc/texlive-en/texlive-en.html#x1-330003.4.4
ln -s /opt/texlive/texdir/texmf-var/fonts/conf/texlive-fontconfig.conf /etc/fonts/conf.d/09-texlive.conf
fc-cache -fv

echo "==> Clean up"
rm -rf \
  /opt/texlive/texdir/install-tl \
  /opt/texlive/texdir/install-tl.log \
  /opt/texlive/texdir/texmf-dist/doc \
  /opt/texlive/texdir/texmf-dist/source \
  /opt/texlive/texdir/texmf-var/web2c/tlmgr.log \
  /setup.sh \
  /texlive.profile \
  /texlive_pgp_keys.asc \
  /tmp/install-tl
