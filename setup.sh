#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

TL_SCHEME=""
TL_VERSION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --texlive-scheme)
            TL_SCHEME="$2"
            shift 2
            ;;
        --texlive-version)
            TL_VERSION="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$TL_SCHEME" ]]; then
    echo "Unknown texlive scheme." >&2
    exit 1
fi

if [[ -z "$TL_VERSION" ]]; then
    echo "Unknown texlive version." >&2
    exit 1
fi

export TL_HISTORIC_REPO="https://ftp.math.utah.edu/pub/tex/historic/systems/texlive"
export TL_INSTALLER_DIR="/tmp/install-tl"
export TL_PREFIX="/opt/texlive"
export TL_PROFILE_FILE="$ROOT_DIR/texlive.profile"
export TL_SCHEME
export TL_VERSION

source "$ROOT_DIR/deps.sh"
source "$ROOT_DIR/texlive.sh"
source "$ROOT_DIR/utils.sh"

detect_os
detect_arch
install_deps
download_installer
install_texlive
postinstall_texlive
cleanup
