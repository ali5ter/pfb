#!/usr/bin/env bash
# @file install.sh
# Install pfb (pretty feedback for bash) to a canonical system location.
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>
# @version 1.1.0
# @date 2026-04-23
# @license MIT
# @usage curl -sL https://raw.githubusercontent.com/ali5ter/pfb/main/install.sh | bash
# @dependencies bash 4.0+, curl or wget
# @exit 0 Success
# @exit 1 Download or install failure

readonly INSTALL_DIR="${HOME}/.local/lib/pfb"
readonly INSTALL_PATH="${INSTALL_DIR}/pfb.sh"
readonly SOURCE_URL="https://raw.githubusercontent.com/ali5ter/pfb/main/pfb.sh"

# @description Print a formatted status line to stderr.
# @param $1 Tag: info | ok | warn | error
# @param $2 Message text
_msg() {
    local tag="$1" msg="$2"
    case "$tag" in
        ok)    printf "  ✓ %s\n" "$msg" ;;
        warn)  printf "  ! %s\n" "$msg" ;;
        error) printf "  ✗ %s\n" "$msg" >&2 ;;
        *)     printf "  %s\n" "$msg" ;;
    esac
}

# @description Download a URL to stdout using curl or wget.
# @param $1 URL to fetch
# @return 0 on success, 1 if no downloader is available or fetch fails
_download() {
    if command -v curl &>/dev/null; then
        curl -fsSL "$1"
    elif command -v wget &>/dev/null; then
        wget -qO- "$1"
    else
        _msg error "curl or wget is required — install one and retry"
        return 1
    fi
}

# @description Extract the PFB_VERSION value from a pfb.sh file.
# @param $1 Path to pfb.sh
# @return Prints version string, empty string if not found
_version_in() {
    grep -m1 'PFB_VERSION=' "$1" 2>/dev/null | sed 's/.*PFB_VERSION="//;s/".*//'
}

# @description Resolve the local pfb.sh when running from a repo clone.
# Returns an empty string when running via curl pipe (no meaningful BASH_SOURCE).
# @return Prints candidate path, or empty string
_local_pfb() {
    local src="${BASH_SOURCE[0]:-}"
    [[ -z "$src" || "$src" == /dev/fd/* || "$src" == /proc/* ]] && { printf ""; return; }
    local dir
    dir="$(cd "$(dirname "$src")" 2>/dev/null && pwd)" || { printf ""; return; }
    printf "%s/pfb.sh" "$dir"
}

main() {
    printf "\npfb installer\n\n"

    # --- Delegate to apt if available (Debian/Ubuntu) -------------------------
    if command -v apt &>/dev/null && command -v dpkg &>/dev/null; then
        _msg info "apt detected — downloading latest .deb from GitHub Releases"
        local deb_url tmpdir
        deb_url="$(curl -fsSL https://api.github.com/repos/ali5ter/pfb/releases/latest \
            | grep '"browser_download_url"' \
            | grep '_all\.deb"' \
            | sed 's/.*"browser_download_url": "//;s/".*//')"
        if [[ -z "$deb_url" ]]; then
            _msg warn "no .deb asset found in latest release — falling back to direct install"
        else
            tmpdir="$(mktemp -d /tmp/pfb.XXXXXX)"
            trap 'rm -rf "$tmpdir"' EXIT
            local deb_file="${tmpdir}/pfb.deb"
            if _download "$deb_url" > "$deb_file"; then
                sudo dpkg -i "$deb_file" && {
                    _msg ok "installed via dpkg → /usr/lib/pfb/pfb.sh"
                    printf "\nAdd this line to your script to source pfb:\n\n"
                    printf "  source \"/usr/lib/pfb/pfb.sh\"\n\n"
                    return 0
                }
            fi
            _msg warn "dpkg install failed — falling back to direct install"
        fi
    fi

    # --- Delegate to Homebrew if available ------------------------------------
    if command -v brew &>/dev/null; then
        _msg info "Homebrew detected — installing via tap"
        brew tap ali5ter/pfb 2>&1 | sed 's/^/  /'
        brew install pfb 2>&1 | sed 's/^/  /'
        local brew_path
        brew_path="$(brew --prefix)/lib/pfb/pfb.sh"
        if [[ -f "$brew_path" ]]; then
            _msg ok "installed via Homebrew → ${brew_path}"
            printf "\nAdd this line to your script to source pfb:\n\n"
            printf "  source \"%s\"\n\n" "$brew_path"
            return 0
        fi
        _msg warn "Homebrew install did not produce expected file — falling back to direct install"
    fi

    # --- Resolve source -------------------------------------------------------
    local local_path use_local=false
    local_path="$(_local_pfb)"
    if [[ -n "$local_path" && -f "$local_path" ]]; then
        use_local=true
        _msg info "source: local copy (${local_path})"
    else
        _msg info "source: ${SOURCE_URL}"
    fi

    # --- Fetch into a temp file -----------------------------------------------
    local tmpfile
    tmpfile="$(mktemp /tmp/pfb.XXXXXX)" || { _msg error "failed to create temp file"; exit 1; }
    trap 'rm -f "$tmpfile"' EXIT

    if $use_local; then
        cp "$local_path" "$tmpfile"
    else
        if ! _download "$SOURCE_URL" > "$tmpfile"; then
            _msg error "download failed — check your network connection and try again"
            exit 1
        fi
    fi

    local new_version
    new_version="$(_version_in "$tmpfile")"
    [[ -z "$new_version" ]] && { _msg error "downloaded file does not look like pfb.sh"; exit 1; }

    # --- Report existing install ----------------------------------------------
    if [[ -f "$INSTALL_PATH" ]]; then
        local old_version
        old_version="$(_version_in "$INSTALL_PATH")"
        _msg info "existing install: v${old_version} at ${INSTALL_PATH}"
    fi

    # --- Install --------------------------------------------------------------
    mkdir -p "$INSTALL_DIR" || { _msg error "could not create ${INSTALL_DIR}"; exit 1; }
    cp "$tmpfile" "$INSTALL_PATH" || { _msg error "could not write to ${INSTALL_PATH}"; exit 1; }
    chmod 644 "$INSTALL_PATH"

    _msg ok "installed v${new_version} → ${INSTALL_PATH}"

    # --- Print usage ----------------------------------------------------------
    printf "\nAdd this line to your script to source pfb:\n\n"
    printf "  source \"%s\"\n" "$INSTALL_PATH"
    printf "\nFor portability across install methods, use a path fallback:\n\n"
    printf "  for _pfb in \\\\\n"
    printf "      \"\$(brew --prefix 2>/dev/null)/lib/pfb/pfb.sh\" \\\\\n"
    printf "      /usr/local/lib/pfb/pfb.sh \\\\\n"
    printf "      /usr/lib/pfb/pfb.sh \\\\\n"
    printf "      ~/.local/lib/pfb/pfb.sh; do\n"
    printf "      [[ -f \"\$_pfb\" ]] && { source \"\$_pfb\"; unset _pfb; break; }\n"
    printf "  done\n\n"
}

main "$@"
