# shellcheck shell=bash

install_deps_debian() {
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
}

install_deps_alpine() {
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
}

install_deps() {
    echo "==> Install system packages."
    if [[ "$OS" = "Debian" ]]; then
        install_deps_debian
    else
        install_deps_alpine
    fi
}
