# shellcheck shell=bash

detect_os() {
    if [[ -f /etc/debian_version ]]; then
        OS="Debian"
    elif [[ -f /etc/alpine-release ]]; then
        OS="Alpine"
    else
        echo "Unknown Linux distribution." >&2
        exit 1
    fi
    export OS
    echo "==> Detect OS: $OS"
}

detect_arch() {
    case "$(uname -m)" in
        x86_64)
            if [[ "$OS" = "Debian" ]]; then
                echo "binary_x86_64-linux 1" >>"$TL_PROFILE_FILE"
                ARCH="x86_64-linux"
            elif [[ "$OS" = "Alpine" ]]; then
                echo "binary_x86_64-linux 0" >>"$TL_PROFILE_FILE"
                echo "binary_x86_64-linuxmusl 1" >>"$TL_PROFILE_FILE"
                ARCH="x86_64-linuxmusl"
            fi
            ;;

        aarch64)
            if [[ "$OS" = "Debian" ]]; then
                echo "binary_aarch64-linux 1" >>"$TL_PROFILE_FILE"
                ARCH="aarch64-linux"
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
    export ARCH
    echo "==> Detect arch: $ARCH"
}

cleanup() {
    echo "==> Clean up."
    rm -rf \
        "$ROOT_DIR" \
        "$TL_INSTALLER_DIR" \
        "$TL_PREFIX/texdir/install-tl" \
        "$TL_PREFIX/texdir/install-tl.log" \
        "$TL_PREFIX/texdir/texmf-dist/doc" \
        "$TL_PREFIX/texdir/texmf-dist/source" \
        "$TL_PREFIX/texdir/texmf-var/web2c/tlmgr.log"

    if [[ "$OS" = "Debian" ]]; then
        apt-get autoremove -y --purge
        apt-get clean -y
    fi
}
