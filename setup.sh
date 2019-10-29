#!/bin/sh

set -e

scheme="$1"

echo "==> Install system packages"
apk --no-cache add \
  ghostscript \
  gnupg \
  perl \
  python \
  tar \
  wget \
  xz

# These are only installed for full scheme
if [ "$scheme" = "full" ]; then
  apk --no-cache add \
    graphviz \
    openjdk11-jre \
    py-pygments \
    ttf-freefont
fi

echo "==> Install TeXLive"
mkdir -p /tmp/install-tl
cd /tmp/install-tl
MIRROR_URL="$(wget -q -S -O /dev/null http://mirror.ctan.org/ 2>&1 | sed -ne 's/.*Location: \(\w*\)/\1/p' | head -n 1)"
wget -nv "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz"
wget -nv "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz.sha512"
wget -nv "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz.sha512.asc"
gpg --import /texlive_pgp_keys.asc
gpg --verify ./install-tl-unx.tar.gz.sha512.asc
sha512sum -c ./install-tl-unx.tar.gz.sha512
mkdir -p /tmp/install-tl/installer
tar --strip-components 1 -zxf /tmp/install-tl/install-tl-unx.tar.gz -C /tmp/install-tl/installer
/tmp/install-tl/installer/install-tl -scheme "$scheme" -profile=/texlive.profile

# Install additional packages for non full scheme
if [ "$scheme" != "full" ]; then
  tlmgr install \
    collection-fontsrecommended \
    biber \
    biblatex \
    latexmk \
    texliveonfly
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
