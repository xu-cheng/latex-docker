#!/bin/sh

set -e
set -o pipefail

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
  ghostscript \
  gnupg \
  graphviz \
  openjdk11-jre-headless \
  perl \
  py-pygments \
  python2 \
  python3 \
  tar \
  ttf-freefont \
  wget \
  xz

# Dependencies needed by latexindent
apk --no-cache add \
  perl-log-dispatch \
  perl-log-log4perl \
  perl-namespace-autoclean \
  perl-params-validationcompiler \
  perl-specio \
  perl-unicode-linebreak \
  perl-yaml-tiny
apk --no-cache \
  --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
  add \
  perl-file-homedir

echo "==> Install TeXLive"
mkdir -p /tmp/install-tl
cd /tmp/install-tl
MIRROR_URL="$(wget -q -S -O /dev/null http://mirror.ctan.org/ 2>&1 | sed -ne 's/.*Location: \(\w*\)/\1/p' | head -n 1)"
wget -nv "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz"
wget -nv "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz.sha512"
wget -nv "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz.sha512.asc"
gpg --no-default-keyring --keyring trustedkeys.kbx --import /texlive_pgp_keys.asc
gpgv ./install-tl-unx.tar.gz.sha512.asc ./install-tl-unx.tar.gz.sha512
sha512sum -c ./install-tl-unx.tar.gz.sha512
mkdir -p /tmp/install-tl/installer
tar --strip-components 1 -zxf /tmp/install-tl/install-tl-unx.tar.gz -C /tmp/install-tl/installer
retry 3 /tmp/install-tl/installer/install-tl -scheme "$scheme" -profile=/texlive.profile

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

# Install additional fonts for full sheme
if [ "$scheme" == "full" ]; then
  apk --no-cache add \
    msttcorefonts-installer \
    fontconfig
  update-ms-fonts
  fc-cache -f
  mktextfm larm1200
fi

echo "==> Clean up"
rm -rf \
  /opt/texlive/texdir/install-tl \
  /opt/texlive/texdir/install-tl.log \
  /opt/texlive/texdir/texmf-dist/doc \
  /opt/texlive/texdir/texmf-dist/source \
  /opt/texlive/texdir/texmf-var/web2c/tlmgr.log \
  /root/.gnupg \
  /setup.sh \
  /texlive.profile \
  /texlive_pgp_keys.asc \
  /tmp/install-tl
