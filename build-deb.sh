#!/usr/bin/env bash
# @file build-deb.sh
# Build a Debian .deb package for pfb without requiring dpkg-deb.
# Assembles the ar archive format used by .deb files using standard
# UNIX utilities (tar, gzip, printf) available on Linux and macOS.
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>
# @version 1.0.0
# @date 2026-04-23
# @license MIT
# @usage ./build-deb.sh [output-dir]
# @param output-dir Optional directory to write the .deb (default: current dir)
# @dependencies bash 4.0+, tar, gzip
# @exit 0 Success — .deb written to output-dir
# @exit 1 Build failure

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TMPDIR=""  # script-level so the EXIT trap can reach it after main() returns
readonly PFB_SH="${SCRIPT_DIR}/pfb.sh"
readonly OUTPUT_DIR="${1:-${SCRIPT_DIR}}"
readonly INSTALL_PATH="/usr/lib/pfb/pfb.sh"

# ---------------------------------------------------------------------------
# Helpers

_msg() {
    local tag="$1" msg="$2"
    case "$tag" in
        ok)    printf "  ✓ %s\n" "$msg" ;;
        info)  printf "  %s\n" "$msg" ;;
        error) printf "  ✗ %s\n" "$msg" >&2 ;;
    esac
}

# @description Extract PFB_VERSION from pfb.sh.
# @return Prints version string
_version() {
    grep -m1 'PFB_VERSION=' "$PFB_SH" | sed 's/.*PFB_VERSION="//;s/".*//'
}

# @description Write a single ar archive entry (60-byte header + data).
# The .deb format uses POSIX/SysV ar, which this replicates with printf.
# @param $1 Member name (max 16 chars)
# @param $2 Path to the data file for this member
_ar_entry() {
    local name="$1" data="$2"
    local size mtime
    size="$(wc -c < "$data" | tr -d ' ')"
    mtime="$(date +%s)"
    # Header: name(16) + mtime(12) + uid(6) + gid(6) + mode(8) + size(10) + magic(2)
    printf '%-16s%-12s%-6s%-6s%-8s%-10s`\n' \
        "$name" "$mtime" "0" "0" "100644" "$size"
    cat "$data"
    # Pad data to even byte boundary
    (( size % 2 == 1 )) && printf '\n' || true
}

# ---------------------------------------------------------------------------
# Main

main() {
    [[ -f "$PFB_SH" ]] || { _msg error "pfb.sh not found at ${PFB_SH}"; exit 1; }

    local version
    version="$(_version)"
    [[ -z "$version" ]] && { _msg error "could not read version from pfb.sh"; exit 1; }

    local pkg="pfb_${version}_all"
    local deb_path="${OUTPUT_DIR}/${pkg}.deb"

    printf "\nbuild-deb: pfb v%s\n\n" "$version"

    # --- Staging directory ----------------------------------------------------
    _TMPDIR="$(mktemp -d /tmp/pfb-deb.XXXXXX)"
    trap 'rm -rf "$_TMPDIR"' EXIT
    local tmpdir="$_TMPDIR"

    # --- debian-binary --------------------------------------------------------
    local f_debian_binary="${tmpdir}/debian-binary"
    printf '2.0\n' > "$f_debian_binary"

    # --- control --------------------------------------------------------------
    local control_root="${tmpdir}/control"
    mkdir -p "$control_root"
    cat > "${control_root}/control" <<EOF
Package: pfb
Version: ${version}
Architecture: all
Maintainer: Alister Lewis-Bowen <alister@lewis-bowen.org>
Installed-Size: $(wc -c < "$PFB_SH" | tr -d ' ')
Description: Pretty feedback for Bash scripts
 Lightweight, dependency-free terminal UI library for Bash.
 Provides log levels, headings, spinners, progress bars, and
 interactive prompts. Source pfb.sh to use in any Bash script.
Homepage: https://github.com/ali5ter/pfb
EOF

    local f_control_tar="${tmpdir}/control.tar.gz"
    tar -czf "$f_control_tar" -C "$control_root" control
    _msg info "control.tar.gz: $(wc -c < "$f_control_tar" | tr -d ' ') bytes"

    # --- data -----------------------------------------------------------------
    local data_root="${tmpdir}/data"
    mkdir -p "${data_root}/usr/lib/pfb"
    cp "$PFB_SH" "${data_root}/usr/lib/pfb/pfb.sh"

    local f_data_tar="${tmpdir}/data.tar.gz"
    tar -czf "$f_data_tar" -C "$data_root" usr
    _msg info "data.tar.gz: $(wc -c < "$f_data_tar" | tr -d ' ') bytes"

    # --- Assemble .deb (ar format) --------------------------------------------
    mkdir -p "$OUTPUT_DIR"
    {
        printf '!<arch>\n'
        _ar_entry "debian-binary" "$f_debian_binary"
        _ar_entry "control.tar.gz" "$f_control_tar"
        _ar_entry "data.tar.gz" "$f_data_tar"
    } > "$deb_path"

    _msg ok "built: ${deb_path} ($(wc -c < "$deb_path" | tr -d ' ') bytes)"
    printf "\nInstall with:\n\n"
    printf "  sudo dpkg -i %s\n" "$deb_path"
    printf "  source %s\n\n" "$INSTALL_PATH"
}

main "$@"
