#!/usr/bin/env bash

set -eo pipefail

scheme="$1"

retry() {
  retries=$1
  shift

  count=0
  until "$@"; do
    exit=$?
    wait="$(echo "2^$count" | bc)"
    count="$(echo "$count + 1" | bc)"
    if [[ "$count" -lt "$retries" ]]; then
      echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
      sleep "$wait"
    else
      echo "Retry $count/$retries exited $exit, no more retries left."
      return "$exit"
    fi
  done
}

if [[ -f /etc/debian_version ]]; then
  OS="Debian"
elif [[ -f /etc/alpine-release ]]; then
  OS="Alpine"
else
  echo "Unknown Linux distribution." >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64)
    if [[ "$OS" = "Debian" ]]; then
      echo "binary_x86_64-linux 1" >>/texlive.profile
      TEX_ARCH=x86_64-linux
    elif [[ "$OS" = "Alpine" ]]; then
      echo "binary_x86_64-linux 0" >>/texlive.profile
      echo "binary_x86_64-linuxmusl 1" >>/texlive.profile
      TEX_ARCH=x86_64-linuxmusl
    fi
    ;;

  aarch64)
    if [[ "$OS" = "Debian" ]]; then
      echo "binary_aarch64-linux 1" >>/texlive.profile
      TEX_ARCH=aarch64-linux
    elif [[ "$OS" = "Alpine" ]]; then
      echo "aarch64 is not supported on Alpine." >&2
      exit 1
    fi
    ;;

  *)
    echo "Unknown arch: $(uname -m)" >&2
    exit 1
    ;;
esac

echo "==> Install system packages"

if [[ "$OS" = "Debian" ]]; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get upgrade -y
  apt-get install -y --no-install-recommends --no-install-suggests \
    curl \
    fontconfig \
    ghostscript \
    git \
    gpg \
    gpg-agent \
    gnuplot-nox \
    graphviz \
    make \
    openjdk-17-jre-headless \
    perl-base \
    python3-minimal \
    python3-pygments \
    tar
elif [[ "$OS" = "Alpine" ]]; then
  apk --no-cache add \
    curl \
    fontconfig \
    ghostscript \
    gnupg \
    gnuplot \
    git \
    graphviz \
    make \
    openjdk21-jre-headless \
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
  apk --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing add \
    perl-file-homedir

  # Dependencies needed by gnuplot
  apk --no-cache add \
    perl-pdf-api2
fi

echo "==> Install TeXLive"
mkdir -p /opt/texlive/
ln -sf "/opt/texlive/texdir/bin/$TEX_ARCH" /opt/texlive/bin
mkdir -p /tmp/install-tl
cd /tmp/install-tl
MIRROR_URL="$(curl -fsS -w "%{redirect_url}" -o /dev/null https://mirror.ctan.org/)"
echo "Use mirror url: ${MIRROR_URL}"
curl -fsSOL "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz"
curl -fsSOL "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz.sha512"
curl -fsSOL "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz.sha512.asc"
gpg --import /texlive_pgp_keys.asc
gpg --verify ./install-tl-unx.tar.gz.sha512.asc ./install-tl-unx.tar.gz.sha512
sha512sum -c ./install-tl-unx.tar.gz.sha512
mkdir -p /tmp/install-tl/installer
tar --strip-components 1 -zxf /tmp/install-tl/install-tl-unx.tar.gz -C /tmp/install-tl/installer
retry 3 /tmp/install-tl/installer/install-tl -scheme "scheme-$scheme" -profile=/texlive.profile

# Install additional packages for non full scheme
if [[ "$scheme" != "full" ]]; then
  tlmgr install \
    collection-fontsrecommended \
    collection-fontutils \
    biber \
    biblatex \
    latexmk \
    texliveonfly \
    xindy
fi

if [[ "$OS" = "Alpine" ]]; then
  # https://github.com/xu-cheng/latex-action/issues/32#issuecomment-626086551
  ln -sf /opt/texlive/texdir/texmf-dist/scripts/xindy/xindy.pl /opt/texlive/texdir/bin/x86_64-linuxmusl/xindy
  ln -sf /opt/texlive/texdir/texmf-dist/scripts/xindy/texindy.pl /opt/texlive/texdir/bin/x86_64-linuxmusl/texindy
  curl -OL https://sourceforge.net/projects/xindy/files/xindy-source-components/2.4/xindy-kernel-3.0.tar.gz
  tar xf xindy-kernel-3.0.tar.gz
  cd xindy-kernel-3.0/src
  apk add clisp --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
  make
  cp -f xindy.mem /opt/texlive/texdir/bin/x86_64-linuxmusl/
  cd -
fi

# System font configuration for XeTeX and LuaTeX
# Ref: https://www.tug.org/texlive/doc/texlive-en/texlive-en.html#x1-330003.4.4
ln -s /opt/texlive/texdir/texmf-var/fonts/conf/texlive-fontconfig.conf /etc/fonts/conf.d/09-texlive.conf
fc-cache -fv

luaotfload-tool --update

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

if [[ "$OS" = "Debian" ]]; then
  apt-get autoremove -y --purge
  apt-get clean -y
fi
