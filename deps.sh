# shellcheck shell=bash

install_deps_debian() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get upgrade -y
    apt-get install -y --no-install-recommends --no-install-suggests \
        curl \
        file \
        fontconfig \
        ghostscript \
        git \
        gnuplot-nox \
        gpg \
        gpg-agent \
        graphviz \
        make \
        openjdk-17-jre-headless \
        perl-base \
        python3-minimal \
        python3-pygments \
        tar

    # Dependencies needed by latexindent
    apt-get install -y --no-install-recommends --no-install-suggests \
        libfile-homedir-perl \
        libunicode-linebreak-perl \
        libyaml-tiny-perl

    # Dependencies needed by gnuplot
    apt-get install -y --no-install-recommends --no-install-suggests \
        libpdf-api2-perl
}

install_deps_alpine() {
    apk --no-cache add \
        curl \
        file \
        fontconfig \
        ghostscript \
        git \
        gnupg \
        gnuplot \
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

    # Dependencies needed by xindy
    apk --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community add \
        clisp
}

install_deps() {
    echo "==> Install system packages."
    if [[ "$OS" = "Debian" ]]; then
        install_deps_debian
    else
        install_deps_alpine
    fi
}
