# shellcheck shell=bash

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

download_installer() {
    local url

    echo "==> Download TeXLive installer."
    if [[ "$TL_VERSION" = "latest" ]]; then
        url="$(curl -fsS -w "%{redirect_url}" -o /dev/null https://mirror.ctan.org/)systems/texlive/tlnet"
        echo "Use mirror url: $url"
    else
        url="$TL_HISTORIC_REPO/$TL_VERSION/tlnet-final"
    fi

    mkdir -p "$TL_INSTALLER_DIR"
    curl -fsSL "$url/install-tl-unx.tar.gz" -o "$TL_INSTALLER_DIR/install-tl-unx.tar.gz"
    curl -fsSL "$url/install-tl-unx.tar.gz.sha512" -o "$TL_INSTALLER_DIR/install-tl-unx.tar.gz.sha512"
    curl -fsSL "$url/install-tl-unx.tar.gz.sha512.asc" -o "$TL_INSTALLER_DIR/install-tl-unx.tar.gz.sha512.asc"

    gpg --import "$ROOT_DIR/texlive_pgp_keys.asc"
    gpg --verify "$TL_INSTALLER_DIR/install-tl-unx.tar.gz.sha512.asc" "$TL_INSTALLER_DIR/install-tl-unx.tar.gz.sha512"
    (
        cd "$TL_INSTALLER_DIR" || exit 1
        sha512sum -c "$TL_INSTALLER_DIR/install-tl-unx.tar.gz.sha512"
    )
    mkdir -p "$TL_INSTALLER_DIR/installer"
    tar --strip-components 1 -zxf "$TL_INSTALLER_DIR/install-tl-unx.tar.gz" -C "$TL_INSTALLER_DIR/installer"
}

install_texlive() {
    echo "==> Install TeXLive."
    mkdir -p "$TL_PREFIX"
    ln -sf "$TL_PREFIX/texdir/bin/$ARCH" "$TL_PREFIX/bin"

    local -a args
    args=("$TL_INSTALLER_DIR/installer/install-tl" -scheme "scheme-$TL_SCHEME" -profile "$TL_PROFILE_FILE")
    if [[ "$TL_VERSION" != "latest" ]]; then
        args+=(-repository "$TL_HISTORIC_REPO/$TL_VERSION/tlnet-final")
    fi
    export TEXLIVE_INSTALL_ENV_NOCHECK=1
    retry 3 "${args[@]}"
}

postinstall_texlive() {
    echo "==> Post-install TeXLive."

    if [[ "$TL_VERSION" != "latest" ]]; then
        tlmgr option repository "$TL_HISTORIC_REPO/$TL_VERSION/tlnet-final"
    fi

    # Install additional packages for non full scheme
    if [[ "$TL_SCHEME" != "full" ]]; then
        tlmgr install \
            collection-fontsrecommended \
            collection-fontutils \
            biber \
            biblatex \
            latexmk \
            texliveonfly \
            xindy
    fi

    # System font configuration for XeTeX and LuaTeX
    # Ref: https://www.tug.org/texlive/doc/texlive-en/texlive-en.html#x1-330003.4.4
    ln -s "$TL_PREFIX/texdir/texmf-var/fonts/conf/texlive-fontconfig.conf" /etc/fonts/conf.d/09-texlive.conf
    fc-cache -fv
    luaotfload-tool --update

    if [[ "$OS" = "Alpine" ]]; then
        # https://github.com/xu-cheng/latex-action/issues/32#issuecomment-626086551
        ln -sf "$TL_PREFIX/texdir/texmf-dist/scripts/xindy/xindy.pl" "$TL_PREFIX/texdir/bin/x86_64-linuxmusl/xindy"
        ln -sf "$TL_PREFIX/texdir/texmf-dist/scripts/xindy/texindy.pl" "$TL_PREFIX/texdir/bin/x86_64-linuxmusl/texindy"
        mkdir -p "$TL_INSTALLER_DIR/xindy"
        curl -fsSL https://sourceforge.net/projects/xindy/files/xindy-source-components/2.4/xindy-kernel-3.0.tar.gz \
            -o "$TL_INSTALLER_DIR/xindy.tar.gz"
        tar --strip-components 2 -zxf "$TL_INSTALLER_DIR/xindy.tar.gz" -C "$TL_INSTALLER_DIR/xindy"
        make -C "$TL_INSTALLER_DIR/xindy"
        cp -f "$TL_INSTALLER_DIR/xindy/xindy.mem" "$TL_PREFIX/texdir/bin/x86_64-linuxmusl/"
    fi
}
