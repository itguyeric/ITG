#!/bin/bash
#
# migrate2rlc - Migrate an EL8 or EL9 distribution to Rocky Linux via CIQ Depot.
# Based on migrate2rocky by Peter Ajamian <peter@pajamian.dhs.org>
# Unified rewrite by CIQ, Inc.
#
# Copyright (c) 2021-2024 Rocky Enterprise Software Foundation
# Copyright (c) 2024 CIQ, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice (including the next
# paragraph) shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

## Using this script means you accept all risks of system instability.

# Bail early if not running under bash >= 4.2.
if [ -n "$POSIXLY_CORRECT" ] || [ -z "$BASH_VERSION" ]; then
    printf '%s\n' "bash >= 4.2 is required for this script." >&2
    exit 1
fi
if (( BASH_VERSINFO[0]*100 + BASH_VERSINFO[1] < 402 )); then
    printf '%s\n' "bash >= 4.2 is required for this script." >&2
    exit 1
fi

set -euo pipefail
shopt -s extglob nullglob

if (( EUID != 0 )); then
    printf '%s\n' \
        "You must run this script as root.  Either use sudo or 'su -c ${0}'" >&2
    exit 1
fi

export LC_ALL=C.UTF-8
unset LANGUAGE CDPATH

###############################################################################
# Section 1: Logging
###############################################################################

logfile=/var/log/migrate2rlc.log

setup_logging() {
    local numlogs=5
    if [[ -e $logfile ]]; then
        if mv -f "$logfile" "$logfile.0" 2>/dev/null; then
            for ((i=numlogs;i>0;i--)); do
                [[ -e "$logfile.$((i-1))" ]] &&
                    mv -f "$logfile.$((i-1))" "$logfile.$i" 2>/dev/null || true
            done
        fi
    fi
    # fd 1 → stdout + logfile, fd 2 → stderr + logfile
    # fd 3 → stdout only, fd 4 → stderr only, fd 5 → logfile only
    # shellcheck disable=SC2094
    exec \
        3>&1 \
        4>&2 \
        5>> "$logfile" \
        > >(tee -a "$logfile") \
        2> >(tee -a "$logfile" >&2)
}

errcolor=$(tput setaf 1 2>/dev/null) || errcolor=
infocolor=$(tput setaf 6 2>/dev/null) || infocolor=
nocolor=$(tput op 2>/dev/null) || nocolor=

msg_format() {
    local _var="$1"; shift
    if (( $# > 1 )); then
        # shellcheck disable=SC2059
        printf -v "$_var" "$@"
    else
        printf -v "$_var" "%b" "$1"
    fi
}

infomsg() {
    local msg; msg_format msg "$@"
    printf '%s' "$msg" >&5
    printf '%s%s%s' "$infocolor" "$msg" "$nocolor" >&3
}

errmsg() {
    local msg; msg_format msg "$@"
    printf '%s' "$msg" >&5
    printf '%s%s%s' "$errcolor" "$msg" "$nocolor" >&4
}

exit_message() {
    errmsg $'\n'"$1"$'\n\n'
    errmsg '%s ' \
        "An error occurred while we were attempting to convert your system to" \
        "Rocky Linux. Your system may be unstable. Script will now exit to" \
        "prevent possible damage."$'\n\n'
    printf '%s%s%s\n' "$infocolor" \
        "A log of this installation can be found at $logfile" \
        "$nocolor" >&3
    exit 1
}

###############################################################################
# Section 2: Version-keyed configuration
###############################################################################

SUPPORTED_MAJORS="8 9"

declare -A GPG_KEY_URL=(
    [8]="https://dl.rockylinux.org/pub/rocky/RPM-GPG-KEY-rockyofficial"
    [9]="https://dl.rockylinux.org/pub/rocky/RPM-GPG-KEY-Rocky-9"
)
declare -A GPG_KEY_SHA512=(
    [8]="88fe66cf0a68648c2371120d56eb509835266d9efdf7c8b9ac8fc101bdf1f0e0197030d3ea65f4b5be89dc9d1ef08581adb068815c88d7b1dc40aa1c32990f6a"
    [9]="ead288baa8daad12d6f340f1a392d47413f8614425673fe310e82d4ead94ca15eb2e1329b30389e6a7f93dd406da255df410306cffd7a1a24f0dfb4c8e23fbfe"
)

# CIQ Depot repo paths (ARCH is appended at runtime)
declare -A DEPOT_REPOS=(
    [8:baseos]="https://depot.ciq.com/dlv2/rocky-8-baseos"
    [8:appstream]="https://depot.ciq.com/dlv2/rocky-8-appstream"
    [8:rlc-core]="https://depot.ciq.com/dlv2/rlc-8-core"
    [9:baseos]="https://depot.ciq.com/dlv2/rocky-9-baseos"
    [9:appstream]="https://depot.ciq.com/dlv2/rocky-9-appstream"
    [9:rlc-core]="https://depot.ciq.com/dlv2/rlc-9-core"
)

# Vault URLs for dead CentOS 8 repos
declare -A VAULT_URLS=(
    [centos:baseos]="https://dl.rockylinux.org/vault/centos/8.5.2111/BaseOS/%ARCH%/os/"
    [centos:appstream]="https://dl.rockylinux.org/vault/centos/8.5.2111/AppStream/%ARCH%/os/"
    [centos:ha]="https://dl.rockylinux.org/vault/centos/8.5.2111/HighAvailability/%ARCH%/os/"
    [centos:powertools]="https://dl.rockylinux.org/vault/centos/8.5.2111/PowerTools/%ARCH%/os/"
    [centos:extras]="https://dl.rockylinux.org/vault/centos/8.5.2111/extras/%ARCH%/os/"
    [centos:devel]="https://dl.rockylinux.org/vault/centos/8.5.2111/Devel/%ARCH%/os/"
    [centos:BaseOS]="https://dl.rockylinux.org/vault/centos/8.5.2111/BaseOS/%ARCH%/os/"
    [centos:AppStream]="https://dl.rockylinux.org/vault/centos/8.5.2111/AppStream/%ARCH%/os/"
    [centos:PowerTools]="https://dl.rockylinux.org/vault/centos/8.5.2111/PowerTools/%ARCH%/os/"
    [centos:Devel]="https://dl.rockylinux.org/vault/centos/8.5.2111/Devel/%ARCH%/os/"
    [centos:HighAvailability]="https://dl.rockylinux.org/vault/centos/8.5.2111/HighAvailability/%ARCH%/os/"
    [centos-stream:baseos]="https://dl.rockylinux.org/vault/centos/8-stream/BaseOS/%ARCH%/os/"
    [centos-stream:appstream]="https://dl.rockylinux.org/vault/centos/8-stream/AppStream/%ARCH%/os/"
    [centos-stream:ha]="https://dl.rockylinux.org/vault/centos/8-stream/HighAvailability/%ARCH%/os/"
    [centos-stream:HighAvailability]="https://dl.rockylinux.org/vault/centos/8-stream/HighAvailability/%ARCH%/os/"
    [centos-stream:powertools]="https://dl.rockylinux.org/vault/centos/8-stream/PowerTools/%ARCH%/os/"
    [centos-stream:nfv]="https://dl.rockylinux.org/vault/centos/8-stream/NFV/%ARCH%/os/"
    [centos-stream:rt]="https://dl.rockylinux.org/vault/centos/8-stream/RT/%ARCH%/os/"
    [centos-stream:RealTime]="https://dl.rockylinux.org/vault/centos/8-stream/RT/%ARCH%/os/"
    [centos-stream:resilientstorage]="https://dl.rockylinux.org/vault/centos/8-stream/ResilientStorage/%ARCH%/os/"
    [centos-stream:centosplus]="https://dl.rockylinux.org/vault/centos/8-stream/centosplus/%ARCH%/os/"
    [centos-stream:cloud]="https://dl.rockylinux.org/vault/centos/8-stream/cloud/%ARCH%/os/"
    [centos-stream:core]="https://dl.rockylinux.org/vault/centos/8-stream/core/%ARCH%/os/"
    [centos-stream:extras]="https://dl.rockylinux.org/vault/centos/8-stream/extras/%ARCH%/os/"
    [centos-stream:extras-common]="https://dl.rockylinux.org/vault/centos/8-stream/extras/%ARCH%/extras-common/"
    [centos-stream:hyperscale]="https://dl.rockylinux.org/vault/centos/8-stream/hyperscale/%ARCH%/os/"
    [centos-stream:kmods]="https://dl.rockylinux.org/vault/centos/8-stream/kmods/%ARCH%/os/"
    [centos-stream:messaging]="https://dl.rockylinux.org/vault/centos/8-stream/messaging/%ARCH%/os/"
    [centos-stream:opstools]="https://dl.rockylinux.org/vault/centos/8-stream/opstools/%ARCH%/os/"
    [centos-stream:storage]="https://dl.rockylinux.org/vault/centos/8-stream/storage/%ARCH%/os/"
    [centos-stream:virt]="https://dl.rockylinux.org/vault/centos/8-stream/virt/%ARCH%/os/"
    [centos-stream:debuginfo]="http://debuginfo.centos.org/8-stream/%ARCH%/"
)

# Disk space requirements (MiB)
declare -A DIR_SPACE_MAP=(
    [/usr]=250
    [/var]=1536
    [/boot]=50
)

# Map for EFI shim/grub arch suffix
declare -A CPU_ARCH_SUFFIX=(
    [x86_64]=x64
    [aarch64]=aa64
)

###############################################################################
# Section 3: Static package lists
###############################################################################

# Packages that identify a source distro — remove whichever are installed.
REMOVE_PKGS=(
    # CentOS Linux
    centos-linux-release centos-gpg-keys centos-linux-repos
    # CentOS Stream
    centos-stream-release centos-stream-repos
    # CentOS branding
    centos-backgrounds centos-logos centos-indexhtml
    centos-logos-ipa centos-logos-httpd
    # RHEL
    redhat-release redhat-release-eula
    redhat-backgrounds redhat-logos redhat-indexhtml
    redhat-logos-ipa redhat-logos-httpd
    # Oracle Linux
    oraclelinux-release
    oraclelinux-release-el8 oraclelinux-release-el9
    oracle-backgrounds oracle-logos oracle-indexhtml
    oracle-logos-ipa oracle-logos-httpd
    oracle-epel-release-el8 oracle-epel-release-el9
    # Rocky (partial installs)
    rocky-release rocky-gpg-keys rocky-repos rocky-obsolete-packages
    rocky-backgrounds rocky-logos rocky-indexhtml
    rocky-logos-ipa rocky-logos-httpd
    # AlmaLinux
    almalinux-release almalinux-gpg-keys almalinux-repos
    almalinux-backgrounds almalinux-logos almalinux-indexhtml
    almalinux-logos-ipa almalinux-logos-httpd
    # Oracle UEK kernels
    kernel-uek kernel-uek-core kernel-uek-modules kernel-uek-modules-core
    # RHEL-specific tools
    libreport-plugin-rhtsupport insights-client
    libreport-rhel libreport-rhel-anaconda-bugzilla libreport-rhel-bugzilla
    # EPEL next (conflicts)
    epel-next-release
)

# EL9-only additional removals
# TODO: openssl-fips-provider-so provides fips-provider-so which openssl-libs
# requires.  Need to check for and fix this broken dep before the swap, or
# handle it during distro-sync so we don't leave a broken RPM database.
REMOVE_PKGS_9=(
    openssl-fips-provider
    openssl-fips-provider-so
)

# RLC packages to always install during the swap (replaces rocky-release, etc.)
# EL9 has rlc-release/rlc-repos/rlc-gpg-keys; EL8 uses ciq-rocky-* naming
RLC_ALWAYS_INSTALL_9=(
    rlc-release
    rlc-repos
    rlc-gpg-keys
)
RLC_ALWAYS_INSTALL_8=(
    ciq-rocky-gpg-keys
    ciq-rocky-cloud-repos
)

# Map of source branding → rocky branding.  If a source package is installed,
# we install the corresponding Rocky package.
declare -A ROCKY_BRANDING_MAP=(
    # Backgrounds
    [centos-backgrounds]=rocky-backgrounds
    [redhat-backgrounds]=rocky-backgrounds
    [oracle-backgrounds]=rocky-backgrounds
    [almalinux-backgrounds]=rocky-backgrounds
    # Logos
    [centos-logos]=rocky-logos
    [redhat-logos]=rocky-logos
    [oracle-logos]=rocky-logos
    [almalinux-logos]=rocky-logos
    # Logos-httpd
    [centos-logos-httpd]=rocky-logos-httpd
    [redhat-logos-httpd]=rocky-logos-httpd
    [oracle-logos-httpd]=rocky-logos-httpd
    [almalinux-logos-httpd]=rocky-logos-httpd
    # Logos-ipa
    [centos-logos-ipa]=rocky-logos-ipa
    [redhat-logos-ipa]=rocky-logos-ipa
    [oracle-logos-ipa]=rocky-logos-ipa
    [almalinux-logos-ipa]=rocky-logos-ipa
    # Indexhtml
    [centos-indexhtml]=rocky-indexhtml
    [redhat-indexhtml]=rocky-indexhtml
    [oracle-indexhtml]=rocky-indexhtml
    [almalinux-indexhtml]=rocky-indexhtml
)

# Stream repos package mapping (stream pkg → rocky pkg)
declare -A STREAM_REPOS_MAP=(
    [centos-stream-repos]=rocky-repos
    [epel-next-release]=epel-release
)

# Always replace these packages from stream with Rocky equivalents
STREAM_ALWAYS_REPLACE=(
    'fwupdate*'
    'grub2-*'
    'shim-*'
    kernel
    'kernel-*'
)

# Module exclusions per major version
declare -A MODULE_EXCLUDES=(
    [8]="libselinux-python:2.8"
    [9]=""
)

# OracleLinux module stream name mappings
# shellcheck disable=SC2034
declare -A MODULE_GLOB_MAP_8=(
    ['%:ol8']=':rhel8'
    ['%:ol']=':rhel'
)
# shellcheck disable=SC2034
declare -A MODULE_GLOB_MAP_9=(
    ['%:ol9']=':rhel9'
    ['%:ol']=':rhel'
)

###############################################################################
# Section 4: Global state
###############################################################################

ARCH=$(arch)
OS_ID=""
OS_MAJOR=""
PRETTY_NAME=""
dist_id=""

depot_username=""
depot_token=""
depot_tier="rlc-pro"
convert_to_rocky=""
verify_all_rpms=""
update_efi=""
convert_info_dir=/root/convert
sm_ca_dir=/etc/rhsm/ca
tmp_dir=""
gpg_key_file=""
gpg_tmp_dir=""
container_macros=""

# Populated during collection phase
declare -a pkgs_to_remove=()
declare -a pkgs_to_install=()
declare -a enabled_modules=()
declare -a disable_modules=()
declare -a installed_sys_stream_repos_pkgs=()
declare -a installed_stream_repos_pkgs=()
declare -a managed_repos=()
declare -a always_install=()
declare -a efi_disk=()
declare -a efi_partition=()
declare -a dist_repourl_swaps=()

###############################################################################
# Section 5: Utility functions
###############################################################################

# Strip empty args from rpm invocations to avoid matching all packages.
saferpm() {
    local -a args=()
    local a
    for a in "$@"; do
        [[ -n $a ]] && args+=("$a")
    done
    rpm "${args[@]}"
}

safednf() {
    local -a args=()
    local a
    for a in "$@"; do
        [[ -n $a ]] && args+=("$a")
    done
    dnf "${args[@]}"
}

###############################################################################
# Section 6: Core functions
###############################################################################

detect_os() {
    if [[ ! -f /etc/os-release ]]; then
        exit_message "/etc/os-release not found.  Cannot detect OS."
    fi

    # shellcheck source=/dev/null
    OS_ID=$(. /etc/os-release && printf '%s' "${ID:-}")
    # shellcheck source=/dev/null
    OS_MAJOR=$(. /etc/os-release && printf '%s' "${VERSION_ID:-}" | cut -d. -f1)
    # shellcheck source=/dev/null
    PRETTY_NAME=$(. /etc/os-release && printf '%s' "${PRETTY_NAME:-unknown}")

    # Distinguish CentOS Linux from CentOS Stream
    if [[ $OS_ID == centos ]] && rpm --quiet -q centos-stream-release 2>/dev/null; then
        dist_id="centos-stream"
    else
        dist_id="$OS_ID"
    fi

    infomsg 'Detected OS: %s (ID=%s, Major=%s)\n' "$PRETTY_NAME" "$OS_ID" "$OS_MAJOR"
}

validate_system() {
    # Check supported major version
    local supported=false
    local v
    for v in $SUPPORTED_MAJORS; do
        if [[ $OS_MAJOR == "$v" ]]; then
            supported=true
            break
        fi
    done
    if [[ $supported != true ]]; then
        exit_message "EL${OS_MAJOR} is not supported.  Supported versions: ${SUPPORTED_MAJORS}"
    fi

    # Check platform
    local platform
    # shellcheck source=/dev/null
    platform=$(. /etc/os-release && printf '%s' "${PLATFORM_ID:-}")
    if [[ $platform != "platform:el${OS_MAJOR}" ]]; then
        exit_message \
"This script must be run on an EL${OS_MAJOR} distribution.  Detected platform: ${platform}"
    fi

    # Katello check
    if [[ -e /etc/rhsm/ca/katello-server-ca.pem ]]; then
        exit_message \
'Migration from Katello-modified systems is not supported.  See the README.'
    fi

    # SUSE Manager check
    if [[ -e /etc/salt/minion.d/susemanager.conf ]]; then
        exit_message \
'Migration from Uyuni/SUSE Manager-modified systems is not supported.'
    fi

    # FIPS check (EL9 only)
    if [[ $OS_MAJOR == "9" ]]; then
        if type fips-mode-setup &>/dev/null && fips-mode-setup --is-enabled 2>/dev/null; then
            exit_message \
'Migration from a system that has FIPS mode enabled is not supported.  '\
'Please disable FIPS mode before running migrate2rlc.'
        fi
    fi

    # dnf database check
    dnf -y check || exit_message \
'Errors found in dnf/rpm database.  Please correct before running migrate2rlc.'

    # Disk space check
    local -A space_map
    local k
    for k in "${!DIR_SPACE_MAP[@]}"; do
        space_map[$k]=${DIR_SPACE_MAP[$k]}
    done
    if ! rpm -q --quiet kernel; then
        space_map[/boot]=0
    fi

    local -a errs=() dirs=("${!space_map[@]}")
    local dir mount avail i=0
    local -A mount_avail_map mount_space_map
    while read -r mount avail; do
        [[ $mount == 'Filesystem' ]] && continue
        dir=${dirs[i++]}
        mount_avail_map[$mount]=${avail%M}
        (( mount_space_map[$mount]=${mount_space_map[$mount]:-0}+${space_map[$dir]} )) || true
    done < <(df -BM --output=source,avail "${dirs[@]}")

    for mount in "${!mount_space_map[@]}"; do
        (( avail = mount_avail_map[$mount]*95/100 )) || true
        if (( avail < mount_space_map[$mount] )); then
            errs+=("Not enough space in $mount, ${mount_space_map[$mount]}M required, ${avail}M available.")
        fi
    done
    if (( ${#errs[@]} )); then
        IFS=$'\n'
        exit_message "${errs[*]}"
    fi

    # Required binaries
    local -a missing=() bins
    bins=(
        rpm dnf awk column tee tput mkdir cat arch sort uniq rmdir df
        rm head curl sha512sum mktemp systemd-detect-virt sed grep
    )
    if [[ $OS_MAJOR == "9" ]]; then
        bins+=(fips-mode-setup)
    fi
    if [[ ${update_efi:-} ]]; then
        bins+=(findmnt grub2-mkconfig efibootmgr mokutil lsblk)
    fi
    for bin in "${bins[@]}"; do
        if ! type "$bin" >/dev/null 2>&1; then
            missing+=("$bin")
        fi
    done
    if (( ${#missing[@]} )); then
        exit_message \
"Commands not found: ${missing[*]}.  Possible bad PATH setting or corrupt installation."
    fi

    # Required packages
    local -A req_pkgs=( [dnf]=4.2 [dnf-plugins-core]=0 )
    local pkg ver
    for pkg in "${!req_pkgs[@]}"; do
        ver=${req_pkgs[$pkg]}
        local installed_ver
        installed_ver=$(rpm -q --qf '%{VERSION}\n' "$pkg" 2>/dev/null) || {
            exit_message "$pkg >= $ver is required.  Please run \"dnf install $pkg\" first."
        }
        if [[ $(printf '%s\n' "$ver" "$installed_ver" | sort -V | head -1) != "$ver" ]]; then
            exit_message "$pkg >= $ver is required.  Installed: $installed_ver."
        fi
    done
}

check_depot() {
    infomsg 'Checking CIQ Depot credentials and availability...\n'
    local test_url
    test_url="${DEPOT_REPOS[${OS_MAJOR}:baseos]}.${ARCH}/repodata/repomd.xml"
    if ! curl -sfLI -u "${depot_username}:${depot_token}" \
        "$test_url" > /dev/null; then
        exit_message \
"CIQ Depot is not accessible.  Check your credentials (-u/-p) and network connectivity."
    fi
    infomsg 'CIQ Depot is accessible.\n'
}

establish_gpg_trust() {
    infomsg 'Establishing GPG trust for Rocky Linux %s...\n' "$OS_MAJOR"
    gpg_tmp_dir="$tmp_dir/gpg"
    mkdir -p "$gpg_tmp_dir"
    gpg_key_file="$gpg_tmp_dir/${GPG_KEY_URL[$OS_MAJOR]##*/}"

    if ! curl -L -o "$gpg_key_file" --silent --show-error \
        "${GPG_KEY_URL[$OS_MAJOR]}"; then
        exit_message "Error downloading the Rocky Linux signing key."
    fi

    if ! sha512sum --quiet -c <<<"${GPG_KEY_SHA512[$OS_MAJOR]} $gpg_key_file"; then
        exit_message "Error validating the Rocky Linux signing key."
    fi
    infomsg 'GPG key verified.\n'
}

fix_dead_repos() {
    # Only needed for CentOS 8 / CentOS Stream 8 — repos are dead.
    [[ $OS_MAJOR == "8" ]] || return 0
    [[ $dist_id == centos || $dist_id == centos-stream ]] || return 0

    infomsg 'Checking for dead CentOS 8 repositories...\n'

    # Get enabled repos
    local -a enabled_repos
    readarray -s 1 -t enabled_repos < <(dnf -q -y repolist --enabled)
    local -A enabled_check
    local r
    for r in "${enabled_repos[@]}"; do
        enabled_check[${r%% *}]=1
    done

    local k d repo_name vault_url
    for k in "${!VAULT_URLS[@]}"; do
        d=${k%%:*}
        repo_name=${k#*:}
        [[ $d == "$dist_id" ]] || continue
        [[ ${enabled_check[$repo_name]:-} ]] || continue

        vault_url=${VAULT_URLS[$k]//%ARCH%/$ARCH}

        # Test if current repo is working
        local current_ok=false
        local repomd_url
        repomd_url=$(dnf -q -y --repo="$repo_name" repoinfo "$repo_name" 2>/dev/null |
            awk '/^Repo-baseurl/{print $3}' | head -1)
        if [[ -n ${repomd_url:-} ]] &&
           curl -sfLI "${repomd_url}repodata/repomd.xml" > /dev/null 2>&1; then
            current_ok=true
        fi

        if [[ $current_ok != true ]]; then
            dist_repourl_swaps+=(
                "--setopt=${repo_name}.mirrorlist="
                "--setopt=${repo_name}.metalink="
                "--setopt=${repo_name}.baseurl="
                "--setopt=${repo_name}.baseurl=${vault_url}"
            )
            infomsg 'Redirecting dead repo %s → %s\n' "$repo_name" "$vault_url"
        fi
    done
}

pre_update() {
    infomsg 'Running dnf update on source distro before migration...\n'
    safednf -y "${dist_repourl_swaps[@]}" update || exit_message \
'Error running pre-update.  Stopping now to avoid putting the system in an
unstable state.  Please correct the issues shown here and try again.'
}

collect_installed_removals() {
    infomsg 'Collecting packages to remove...\n'
    local -a candidates=("${REMOVE_PKGS[@]}")
    if [[ $OS_MAJOR == "9" ]]; then
        candidates+=("${REMOVE_PKGS_9[@]}")
    fi

    pkgs_to_remove=()
    local pkg
    for pkg in "${candidates[@]}"; do
        if rpm --quiet -q "$pkg" 2>/dev/null; then
            pkgs_to_remove+=("$pkg")
        fi
    done

    if (( ${#pkgs_to_remove[@]} == 0 )); then
        exit_message "No source distro packages found to remove.  Is this already Rocky Linux?"
    fi

    infomsg 'Found %d packages to remove: %s\n' \
        "${#pkgs_to_remove[@]}" "${pkgs_to_remove[*]}"
}

collect_rocky_installs() {
    infomsg 'Determining Rocky Linux packages to install...\n'
    # Use version-appropriate RLC package names
    local -n _rlc_pkgs="RLC_ALWAYS_INSTALL_${OS_MAJOR}"
    pkgs_to_install=("${_rlc_pkgs[@]}")

    # Check branding map — if a source branding pkg is installed, add its Rocky equivalent
    local src_pkg rocky_pkg
    local -A seen=()
    for src_pkg in "${!ROCKY_BRANDING_MAP[@]}"; do
        rocky_pkg=${ROCKY_BRANDING_MAP[$src_pkg]}
        if rpm --quiet -q "$src_pkg" 2>/dev/null && [[ ! ${seen[$rocky_pkg]:-} ]]; then
            pkgs_to_install+=("$rocky_pkg")
            seen[$rocky_pkg]=1
        fi
    done

    infomsg 'Rocky packages to install: %s\n' "${pkgs_to_install[*]}"
}

collect_modules() {
    infomsg 'Collecting enabled module streams...\n'
    enabled_modules=()
    disable_modules=()

    # Collect currently enabled modules from system repos
    local -a raw_modules=()
    readarray -t raw_modules < <(
        dnf -y -q module list --enabled 2>/dev/null |
        awk '
            $1 == "@modulefailsafe", /^$/ {next}
            $1 == "Name", /^$/ {if ($1!="Name" && !/^$/) print $1":"$2}
        ' | sort -u
    ) || true

    # Apply OL→RHEL module stream name mapping
    local -n mod_map="MODULE_GLOB_MAP_${OS_MAJOR}"
    local i gl repl mod
    for i in "${!raw_modules[@]}"; do
        mod=${raw_modules[i]}
        for gl in "${!mod_map[@]}"; do
            repl=${mod_map[$gl]}
            mod=${mod/$gl/$repl}
        done
        if [[ $mod != "${raw_modules[i]}" ]]; then
            disable_modules+=("${raw_modules[i]}")
        fi
        enabled_modules+=("$mod")
    done

    # Remove excluded modules
    local excludes_str="${MODULE_EXCLUDES[$OS_MAJOR]:-}"
    if [[ -n $excludes_str ]]; then
        local -a excludes
        IFS=' ' read -r -a excludes <<<"$excludes_str"
        local -A excl_check=()
        local m
        for m in "${excludes[@]}"; do
            excl_check[$m]=1
        done
        local -a filtered=()
        for m in "${enabled_modules[@]}"; do
            [[ ! ${excl_check[$m]:-} ]] && filtered+=("$m")
        done
        enabled_modules=("${filtered[@]}")
    fi

    if (( ${#enabled_modules[@]} )); then
        infomsg 'Modules to re-enable: %s\n' "${enabled_modules[*]}"
    fi
}

handle_stream_repos() {
    # CentOS Stream: rpm -e --justdb the stream repos pkg, rename repo files
    [[ $dist_id == centos-stream ]] || return 0

    infomsg 'Handling CentOS Stream repositories...\n'
    installed_sys_stream_repos_pkgs=()
    installed_stream_repos_pkgs=()

    local stream_pkg rocky_pkg
    for stream_pkg in "${!STREAM_REPOS_MAP[@]}"; do
        rocky_pkg=${STREAM_REPOS_MAP[$stream_pkg]}
        if rpm --quiet -q "$stream_pkg" 2>/dev/null; then
            # Is this a system-level repos package that maps to a Rocky equivalent?
            if [[ $rocky_pkg == rocky-repos ]]; then
                installed_sys_stream_repos_pkgs+=("$stream_pkg")
            else
                installed_stream_repos_pkgs+=("$stream_pkg")
            fi
        fi
    done

    if (( ${#installed_sys_stream_repos_pkgs[@]} == 0 &&
          ${#installed_stream_repos_pkgs[@]} == 0 )); then
        return 0
    fi

    # Get repo files from these packages
    local -a repos_files=()
    readarray -t repos_files < <(
        saferpm -ql "${installed_sys_stream_repos_pkgs[@]}" \
            "${installed_stream_repos_pkgs[@]}" 2>/dev/null |
        grep '^/etc/yum\.repos\.d/.\+\.repo$'
    ) || true

    # Remove system stream repos packages from rpm db (keep files)
    if (( ${#installed_sys_stream_repos_pkgs[@]} )); then
        infomsg 'Removing stream repos packages from rpm db: %s\n' \
            "${installed_sys_stream_repos_pkgs[*]}"
        saferpm -e --justdb --nodeps -a "${installed_sys_stream_repos_pkgs[@]}" ||
            exit_message \
"Could not remove packages from rpm db: ${installed_sys_stream_repos_pkgs[*]}"
        # Remove these from our removal list since they're already gone from rpm db
        local -A stream_removed=()
        local p
        for p in "${installed_sys_stream_repos_pkgs[@]}"; do
            stream_removed[$p]=1
        done
        local -a new_remove=()
        for p in "${pkgs_to_remove[@]}"; do
            [[ ! ${stream_removed[$p]:-} ]] && new_remove+=("$p")
        done
        pkgs_to_remove=("${new_remove[@]}")
    fi

    # Rename repo sections and fix baseurl
    if (( ${#repos_files[@]} )); then
        local stream_prefix="stream-"
        if [[ $OS_MAJOR == "8" ]]; then
            # shellcheck disable=SC2016
            sed -i \
                -e 's/^\[/['"$stream_prefix"'/' \
                -e 's|^mirrorlist=|#mirrorlist=|' \
                -e 's|^#baseurl=http://mirror.centos.org/$contentdir/$stream/|baseurl=https://dl.rockylinux.org/vault/centos/8-stream/|' \
                -e 's|^baseurl=http://vault.centos.org/$contentdir/$stream/|baseurl=https://dl.rockylinux.org/vault/centos/8-stream/|' \
                "${repos_files[@]}"
        else
            # shellcheck disable=SC2016
            sed -i \
                -e 's/^\[/['"$stream_prefix"'/' \
                -e 's|^mirrorlist=|#mirrorlist=|' \
                -e 's|^#baseurl=http://mirror.centos.org/$contentdir/$stream/|baseurl=http://mirror.centos.org/centos/'"${OS_MAJOR}"'-stream/|' \
                -e 's|^baseurl=http://vault.centos.org/$contentdir/$stream/|baseurl=https://vault.centos.org/centos/'"${OS_MAJOR}"'-stream/|' \
                "${repos_files[@]}"
        fi
        infomsg 'Stream repo files renamed with stream- prefix.\n'
    fi
}

handle_subscription_manager() {
    # RHEL: backup SM certs, disable managed repos
    [[ $dist_id == rhel ]] || return 0

    infomsg 'Handling subscription-manager for RHEL migration...\n'

    # Backup SM certs
    if [[ -d $sm_ca_dir ]] && \
       ( shopt -s failglob dotglob; : "$sm_ca_dir"/* ) 2>/dev/null; then
        local tmp_sm_ca_dir="$tmp_dir/sm-certs"
        mkdir -p "$tmp_sm_ca_dir"
        cp -f -dR --preserve=all "$sm_ca_dir"/* "$tmp_sm_ca_dir/" ||
            exit_message "Could not backup subscription-manager certs"
        infomsg 'Subscription Manager certificates backed up.\n'
    fi

    # Detect managed repos
    managed_repos=()
    local repo_file
    for repo_file in /etc/yum.repos.d/*.repo; do
        [[ -f $repo_file ]] || continue
        local managed
        managed=$(awk '
            BEGIN {FS="[)(]"}
            /^# Managed by \(.*\) subscription-manager$/ {print $2}
        ' < "$repo_file")
        if [[ -n ${managed:-} ]]; then
            local repo_ids
            repo_ids=$(awk '/^\[/{gsub(/[\[\]]/,"",$1); print $1}' "$repo_file")
            local rid
            for rid in $repo_ids; do
                managed_repos+=("$rid")
            done
        fi
    done

    if (( ${#managed_repos[@]} )); then
        infomsg 'Found %d subscription-managed repos to disable after swap.\n' \
            "${#managed_repos[@]}"
    fi
}

swap_packages() {
    infomsg $'\n=== Performing package swap ===\n\n'

    # Build dnf parameters for CIQ Depot repos
    local -a dnfparams=()
    local repo_key repo_url repo_id
    for repo_key in "baseos" "appstream"; do
        repo_url="${DEPOT_REPOS[${OS_MAJOR}:${repo_key}]}.${ARCH}/"
        repo_id="rocky${repo_key}"
        dnfparams+=(
            "--repofrompath=${repo_id},${repo_url}"
            "--setopt=${repo_id}.gpgcheck=1"
            "--setopt=${repo_id}.gpgkey=file://${gpg_key_file}"
            "--setopt=${repo_id}.username=${depot_username}"
            "--setopt=${repo_id}.password=${depot_token}"
        )
    done

    # Add rlc-core repo for rlc-release, rlc-repos, rlc-gpg-keys
    repo_url="${DEPOT_REPOS[${OS_MAJOR}:rlc-core]}.${ARCH}/"
    repo_id="rlccore"
    dnfparams+=(
        "--repofrompath=${repo_id},${repo_url}"
        "--setopt=${repo_id}.gpgcheck=0"
        "--setopt=${repo_id}.username=${depot_username}"
        "--setopt=${repo_id}.password=${depot_token}"
    )

    infomsg 'Packages to remove: %s\n' "${pkgs_to_remove[*]}"
    infomsg 'Packages to install: %s\n' "${pkgs_to_install[*]}"

    # Fix: /usr/share/redhat-release may exist as a directory on RHEL but
    # rlc-release expects it as a file, causing cpio unpack errors.
    if [[ -d /usr/share/redhat-release ]]; then
        infomsg 'Removing /usr/share/redhat-release directory (conflicts with rlc-release)...\n'
        rm -rf /usr/share/redhat-release
    fi

    # Use dnf shell for atomic remove+install
    safednf -y shell --disablerepo='*' --noautoremove \
        "${dist_repourl_swaps[@]}" \
        --setopt=protected_packages= --setopt=keepcache=True \
        "${dnfparams[@]}" \
        <<EOF
remove ${pkgs_to_remove[*]}
install ${pkgs_to_install[*]}
run
exit
EOF

    infomsg 'Package swap completed.\n'
}

verify_swap() {
    infomsg 'Verifying package swap...\n'

    # Check that old packages were removed
    local -a still_installed=()
    local pkg
    for pkg in "${pkgs_to_remove[@]}"; do
        if rpm --quiet -q "$pkg" 2>/dev/null; then
            still_installed+=("$pkg")
        fi
    done

    if (( ${#still_installed[@]} )); then
        infomsg 'Forcibly removing leftover packages: %s\n' "${still_installed[*]}"
        for pkg in "${still_installed[@]}"; do
            saferpm -e --allmatches --nodeps "$pkg" 2>/dev/null ||
            saferpm -e --allmatches --nodeps --noscripts --notriggers "$pkg" 2>/dev/null || true
        done
    fi

    # Check that new packages were installed
    local -a not_installed=()
    for pkg in "${pkgs_to_install[@]}"; do
        if ! rpm --quiet -q "$pkg" 2>/dev/null; then
            not_installed+=("$pkg")
        fi
    done

    if (( ${#not_installed[@]} )); then
        infomsg 'Force-installing missing packages: %s\n' "${not_installed[*]}"
        local -A rpm_map=()
        local rpm_file
        for rpm_file in /var/cache/dnf/{rockybaseos,rockyappstream,rlccore}-*/packages/*.rpm; do
            [[ -f $rpm_file ]] || continue
            local rname
            rname=$(rpm -q --qf '%{NAME}\n' --nodigest "$rpm_file" 2>/dev/null) || continue
            rpm_map[$rname]=$rpm_file
        done
        local -a file_list
        for pkg in "${not_installed[@]}"; do
            if [[ ! ${rpm_map[$pkg]:-} ]]; then
                errmsg 'Warning: Could not find cached RPM for %s\n' "$pkg"
                continue
            fi
            printf '%s\n' "$pkg"
            if ! rpm -i --force --nodeps --nodigest "${rpm_map[$pkg]}" \
                2>/dev/null; then
                # Install into db first, then clean up conflicting files
                rpm -i --force --justdb --nodeps --nodigest \
                    "${rpm_map[$pkg]}" 2>/dev/null || true
                readarray -t file_list < <(
                    rpm -V "$pkg" 2>/dev/null | awk '$1!="missing" {print $2}'
                ) || true
                local file
                for file in "${file_list[@]}"; do
                    rmdir "$file" 2>/dev/null ||
                    rm -f "$file" 2>/dev/null ||
                    rm -rf "$file" 2>/dev/null || true
                done
                rpm -i --reinstall --force --nodeps --nodigest \
                    "${rpm_map[$pkg]}" 2>/dev/null || true
            fi
        done
    fi

    # Clean up GPG temp dir now that rocky-gpg-keys is installed
    [[ -d ${gpg_tmp_dir:-} ]] && rm -rf "$gpg_tmp_dir"

    infomsg 'Package swap verification complete.\n'
}

disable_managed_repos() {
    # Disable subscription-managed repos (RHEL)
    if (( ${#managed_repos[@]} )); then
        # Filter for repos that still exist
        local -a existing_managed=()
        readarray -t existing_managed < <(
            safednf -y -q repolist "${managed_repos[@]}" 2>/dev/null |
                awk '$1!="repo" {print $1}'
        ) || true
        if (( ${#existing_managed[@]} )); then
            infomsg 'Disabling subscription-managed repos: %s\n' "${existing_managed[*]}"
            safednf -y --enableplugin=config_manager config-manager \
                --disable "${existing_managed[@]}" || true
        fi
    fi
}

restore_modules() {
    if (( ${#disable_modules[@]} )); then
        infomsg 'Disabling renamed modules...\n'
        safednf -y module disable "${disable_modules[@]}" ||
            infomsg 'Warning: Failed to disable modules: %s (continuing anyway)\n' "${disable_modules[*]}"
    fi

    if (( ${#enabled_modules[@]} )); then
        infomsg 'Re-enabling modules: %s\n' "${enabled_modules[*]}"
        safednf -y module enable "${enabled_modules[@]}" ||
            infomsg 'Warning: Failed to enable modules: %s (continuing anyway)\n' "${enabled_modules[*]}"
    fi

    # Disable excluded modules
    local excludes_str="${MODULE_EXCLUDES[$OS_MAJOR]:-}"
    if [[ -n $excludes_str ]]; then
        local -a excludes
        IFS=' ' read -r -a excludes <<<"$excludes_str"
        infomsg 'Disabling excluded modules: %s\n' "${excludes[*]}"
        safednf -y module disable "${excludes[@]}" || true
    fi
}

distro_sync() {
    infomsg $'\nRunning distro-sync...\n\n'

    # Pre-distro-sync cleanup: Remove Oracle-specific packages that may have been
    # pulled in during the swap phase and will cause file conflicts with Rocky
    # equivalents during distro-sync.
    if [[ $OS_MAJOR == "9" ]]; then
        for conflict_pkg in openssl-fips-provider-so; do
            if rpm --quiet -q "$conflict_pkg" 2>/dev/null; then
                infomsg 'Removing conflicting package: %s\n' "$conflict_pkg"
                rpm -e --nodeps "$conflict_pkg" 2>/dev/null || true
            fi
        done
    fi

    local -a ds_args=(-y)
    if [[ $OS_MAJOR == "9" ]] || [[ $OS_MAJOR == "8" ]]; then
        ds_args+=(--allowerasing)
    fi
    dnf "${ds_args[@]}" distro-sync || {
        errmsg 'Warning: distro-sync returned non-zero exit code.\n'
        # Check if essential release packages are installed despite the error
        if rpm -q rlc-release rocky-release &>/dev/null; then
            infomsg 'Essential release packages are present, continuing...\n'
        else
            exit_message "Error during distro-sync — essential release packages missing."
        fi
    }

    # Handle stream repos post-sync
    if (( ${#installed_sys_stream_repos_pkgs[@]} ||
          ${#installed_stream_repos_pkgs[@]} )); then
        local stream_prefix="stream-"
        dnf -y --enableplugin=config_manager config-manager --set-disabled \
            "${stream_prefix}*" 2>/dev/null ||
            errmsg 'Warning: Failed to disable stream repos, please check manually.\n'

        if (( ${#STREAM_ALWAYS_REPLACE[@]} )); then
            local -a stream_installed=()
            local sp
            for sp in "${STREAM_ALWAYS_REPLACE[@]}"; do
                if [[ $(saferpm -qa "$sp" 2>/dev/null) ]]; then
                    stream_installed+=("$sp")
                fi
            done
            if (( ${#stream_installed[@]} )); then
                safednf -y distro-sync "${stream_installed[@]}" ||
                    errmsg 'Warning: Error during stream package distro-sync.\n'
            fi
        fi

        infomsg $'\nCentOS Stream Migration Notes:\n'
        infomsg '%s\n' \
'Newer package versions from CentOS Stream have been retained.  Stream' \
'repositories have been renamed with a "stream-" prefix and disabled.' \
'Future updates will come from Rocky Linux repositories.'
    fi

    # Subscription manager advisory
    if rpm --quiet -q subscription-manager 2>/dev/null; then
        infomsg $'\nSubscription Manager is still installed.  You may remove it with:\n'
        infomsg '  dnf remove subscription-manager dnf-plugin-subscription-manager\n'
    fi

    # Install EFI-required packages
    if (( ${#always_install[@]} )); then
        safednf -y install "${always_install[@]}" || exit_message \
            "Error installing required packages: ${always_install[*]}"
    fi

    # Restore SM certs if they were removed during swap
    if [[ -d "$tmp_dir/sm-certs" ]]; then
        local -a removed_certs=()
        readarray -t removed_certs < <((
            shopt -s nullglob dotglob
            local -a certs=()
            cd "$sm_ca_dir" 2>/dev/null && certs=(*)
            cd "$tmp_dir/sm-certs" && certs+=(*)
            IFS=$'\n'
            printf '%s' "${certs[*]}"
        ) | sort | uniq -u) || true
        if (( ${#removed_certs[@]} )); then
            cp -n -dR --preserve=all "$tmp_dir/sm-certs"/* "$sm_ca_dir/" ||
                errmsg 'Warning: Could not restore SM certs to %s\n' "$sm_ca_dir"
            infomsg 'Restored subscription-manager certificates: %s\n' "${removed_certs[*]}"
        fi
    fi
}

efi_check() {
    if ! [[ -d /sys/class/block ]]; then
        exit_message "/sys is not accessible."
    fi
    if systemd-detect-virt --quiet --container 2>/dev/null; then
        container_macros=$(mktemp /etc/rpm/macros.zXXXXXX)
        printf '%s\n' '%_netsharedpath /sys:/proc' > "$container_macros"
    elif [[ -d /sys/firmware/efi/ ]]; then
        update_efi=true
    fi
}

collect_efi_info() {
    [[ ${update_efi:-} ]] || return 0

    local efi_mount kname
    efi_mount=$(findmnt --mountpoint /boot/efi --output SOURCE --noheadings) ||
        exit_message "Can't find EFI mount.  No EFI boot detected."
    kname=$(lsblk -dno kname "$efi_mount")
    efi_disk=("$(lsblk -dno pkname "/dev/$kname")")

    if [[ ${efi_disk[0]} ]]; then
        efi_partition=("$(<"/sys/block/${efi_disk[0]}/$kname/partition")")
    else
        # md-raid or virtual disk — find physical backing
        local orig_dir
        orig_dir=$(pwd)
        cd "/sys/block/$kname/slaves" || exit_message \
"Unable to gather EFI data: Can't cd to /sys/block/$kname/slaves."
        if ! (shopt -s failglob; : ./*) 2>/dev/null; then
            exit_message \
"Unable to gather EFI data: No slaves found in /sys/block/$kname/slaves."
        fi
        efi_disk=()
        efi_partition=()
        local d
        for d in *; do
            efi_disk+=("$(lsblk -dno pkname "/dev/$d")")
            efi_partition+=("$(<"$d/partition")")
            if [[ ! ${efi_disk[-1]} || ! ${efi_partition[-1]} ]]; then
                exit_message \
"Unable to gather EFI data: Can't find disk/partition for $d."
            fi
        done
        cd "$orig_dir"
    fi

    always_install+=(
        "shim-${CPU_ARCH_SUFFIX[$ARCH]}"
        "grub2-efi-${CPU_ARCH_SUFFIX[$ARCH]}"
    )
}

fix_efi() {
    [[ ${update_efi:-} ]] || return 0
    infomsg 'Updating EFI boot configuration...\n'
    grub2-mkconfig -o /boot/efi/EFI/rocky/grub.cfg ||
        exit_message "Error updating the grub config."
    local i
    for i in "${!efi_disk[@]}"; do
        efibootmgr -c -d "/dev/${efi_disk[i]}" -p "${efi_partition[i]}" \
            -L "Rocky Linux" \
            -l "/EFI/rocky/shim${CPU_ARCH_SUFFIX[$ARCH]}.efi" ||
            exit_message "Error updating uEFI firmware."
    done
    infomsg 'EFI boot updated.\n'
}

configure_depot_repos() {
    infomsg 'Configuring CIQ Depot repositories...\n'

    # rlc-repos blanks out rocky.repo etc. with a comment pointing to depot.
    # It ships NO actual repo definitions — those come from 'depot enable'.
    # Since we embed credentials directly, we write the repo file ourselves.
    local depot_file="/etc/yum.repos.d/depot-rlc.repo"
    local ciq_gpg="https://ciq.com/keys/rpm-gpg-key-ciq"
    local rocky_gpg="http://download.rockylinux.org/pub/rocky/RPM-GPG-KEY-Rocky-${OS_MAJOR}"
    local base="https://depot.ciq.com/dlv2"

    cat > "$depot_file" <<EOF
# CIQ Depot repositories - configured by migrate2rlc

[rlc-${OS_MAJOR}-core.${ARCH}]
name = Rocky Linux ${OS_MAJOR} from CIQ - Core (${ARCH})
baseurl = ${base}/rlc-${OS_MAJOR}-core.${ARCH}
username = ${depot_username}
password = ${depot_token}
gpgkey = ${ciq_gpg}
metadata_expire = 43200
priority = 50
repo_gpgcheck = false
gpgcheck = false
enabled = true
skip_if_unavailable = true

[rlc-${OS_MAJOR}-supplemental.${ARCH}]
name = Rocky Linux ${OS_MAJOR} from CIQ - Supplemental (${ARCH})
baseurl = ${base}/rlc-${OS_MAJOR}-supplemental.${ARCH}
username = ${depot_username}
password = ${depot_token}
gpgkey = ${ciq_gpg}
metadata_expire = 43200
priority = 50
repo_gpgcheck = false
gpgcheck = false
enabled = true
skip_if_unavailable = true

[rocky-${OS_MAJOR}-baseos.${ARCH}]
name = Rocky Linux ${OS_MAJOR} BaseOS (${ARCH})
baseurl = ${base}/rocky-${OS_MAJOR}-baseos.${ARCH}
username = ${depot_username}
password = ${depot_token}
gpgkey = ${rocky_gpg}
metadata_expire = 43200
priority = 50
repo_gpgcheck = false
gpgcheck = false
enabled = true
skip_if_unavailable = true

[rocky-${OS_MAJOR}-appstream.${ARCH}]
name = Rocky Linux ${OS_MAJOR} AppStream (${ARCH})
baseurl = ${base}/rocky-${OS_MAJOR}-appstream.${ARCH}
username = ${depot_username}
password = ${depot_token}
gpgkey = ${rocky_gpg}
metadata_expire = 43200
priority = 50
repo_gpgcheck = false
gpgcheck = false
enabled = true
skip_if_unavailable = true

[rocky-${OS_MAJOR}-extras.${ARCH}]
name = Rocky Linux ${OS_MAJOR} extras (${ARCH})
baseurl = ${base}/rocky-${OS_MAJOR}-extras.${ARCH}
username = ${depot_username}
password = ${depot_token}
gpgkey = ${rocky_gpg}
metadata_expire = 43200
priority = 50
repo_gpgcheck = false
gpgcheck = false
enabled = true
skip_if_unavailable = true
EOF

    infomsg 'Created %s with CIQ Depot repositories.\n' "$depot_file"

    # Disable all non-depot repos to prevent broken mirrorlist errors
    # The rlc-repos package ships repo files with mirrorlists that point to
    # mirrors.rockylinux.org, which don't carry RLC packages.  These repos
    # will cause dnf failures during distro-sync and later operations.
    infomsg 'Disabling non-depot repository files to prevent mirrorlist errors...\n'
    local repo_file
    for repo_file in /etc/yum.repos.d/*.repo; do
        [[ -f $repo_file ]] || continue
        # Skip our own depot repo file
        [[ $repo_file == "$depot_file" ]] && continue
        # Disable all enabled repos in this file
        if grep -q '^\s*enabled\s*=\s*1' "$repo_file" 2>/dev/null; then
            sed -i 's/^\(\s*enabled\s*=\s*\)1/\10/' "$repo_file"
            infomsg '  Disabled repos in %s\n' "$repo_file"
        fi
    done
    infomsg 'Non-depot repos disabled.\n'
}

install_depot_cli() {
    infomsg $'\nInstalling CIQ Depot CLI...\n'
    if ! safednf install -y \
        "https://depot.ciq.com/public/files/depot-client/depot/depot.${ARCH}.rpm"; then
        errmsg 'Warning: Failed to install Depot CLI.  You may need to install it manually.\n'
        return 0
    fi
    infomsg 'Depot CLI installed successfully.\n'

    # Authenticate with depot
    infomsg 'Logging into CIQ Depot...\n'
    if ! depot login -u "${depot_username}" -t "${depot_token}"; then
        errmsg 'Warning: depot login failed.  You may need to run "depot login" manually.\n'
        return 0
    fi
    infomsg 'Depot login successful.\n'

    # Enable the RLC product — this creates depot-managed repo files
    local product="${depot_tier}-${OS_MAJOR}"
    infomsg 'Enabling RLC product %s via depot...\n' "$product"
    if ! depot enable "$product"; then
        errmsg 'Warning: depot enable failed.  You may need to run "depot enable %s" manually.\n' "$product"
        return 0
    fi
    infomsg 'Depot product %s enabled.\n' "$product"

    # Remove our temporary repo file — depot now manages the repos
    local depot_file="/etc/yum.repos.d/depot-rlc.repo"
    if [[ -f $depot_file ]]; then
        rm -f "$depot_file"
        infomsg 'Removed temporary %s (depot now manages repos).\n' "$depot_file"
    fi
}

install_kernel_if_needed() {
    # After migrating from Oracle Linux with UEK, the UEK kernel packages are
    # removed but no RHCK (Red Hat Compatible Kernel) may be installed, leaving
    # the system unbootable.  This function checks for an installed kernel and
    # installs one if missing.
    infomsg 'Checking for installed kernel...\n'

    if rpm -q kernel &>/dev/null || rpm -q kernel-core &>/dev/null; then
        infomsg 'Kernel package found, no action needed.\n'
        return 0
    fi

    errmsg 'Warning: No bootable kernel found!  Installing kernel...\n'

    # distro-sync may have installed rlc-repos which creates repo files with
    # broken mirrorlists (pointing to mirrors.rockylinux.org which doesn't
    # carry RLC packages).  Disable all non-depot repos before installing.
    local depot_file="/etc/yum.repos.d/depot-rlc.repo"
    local repo_file
    for repo_file in /etc/yum.repos.d/*.repo; do
        [[ -f $repo_file ]] || continue
        [[ $repo_file == "$depot_file" ]] && continue
        if grep -q '^\s*enabled\s*=\s*1' "$repo_file" 2>/dev/null; then
            sed -i 's/^\(\s*enabled\s*=\s*\)1/\10/' "$repo_file"
            infomsg '  Disabled repos in %s\n' "$repo_file"
        fi
    done
    dnf clean all >/dev/null 2>&1 || true

    # distro-sync may have replaced firewalld, causing a reload that breaks
    # DNS resolution (especially in NAT/bridged environments).  Check DNS
    # and restart networking if needed.
    if ! getent hosts depot.ciq.com &>/dev/null; then
        infomsg 'DNS resolution failed, attempting to restore network connectivity...\n'
        systemctl restart NetworkManager 2>/dev/null || true
        systemctl restart systemd-resolved 2>/dev/null || true
        # If firewalld reload broke DNS, temporarily stop it
        systemctl stop firewalld 2>/dev/null || true
        sleep 2
        if ! getent hosts depot.ciq.com &>/dev/null; then
            errmsg 'Warning: DNS still not working after network restart.\n'
        fi
    fi

    if safednf install -y kernel kernel-core kernel-modules; then
        infomsg 'Kernel installed successfully.\n'
    else
        errmsg 'Warning: Failed to install kernel via dnf.  Trying with --allowerasing...\n'
        if dnf install -y --allowerasing kernel kernel-core kernel-modules; then
            infomsg 'Kernel installed successfully with --allowerasing.\n'
        else
            exit_message "CRITICAL: Failed to install a kernel.  System may be unbootable!"
        fi
    fi
}

generate_rpm_info() {
    mkdir -p "$convert_info_dir"
    infomsg 'Creating a list of RPMs installed: %s\n' "$1"
    rpm -qa --qf \
"%{NAME}|%{VERSION}|%{RELEASE}|%{INSTALLTIME}|%{VENDOR}|%{BUILDTIME}|\
%{BUILDHOST}|%{SOURCERPM}|%{LICENSE}|%{PACKAGER}\n" |
        sort > "${convert_info_dir}/${HOSTNAME}-rpm-list-${1}.log"
    infomsg 'Verifying RPMs installed against RPM database: %s\n\n' "$1"
    rpm -Va | sort -k3 > \
        "${convert_info_dir}/${HOSTNAME}-rpm-list-verified-${1}.log" || true
}

###############################################################################
# Section 7: Cleanup
###############################################################################

exit_clean() {
    [[ -d ${tmp_dir:-} ]] && rm -rf "$tmp_dir"
    [[ -f ${container_macros:-} ]] && rm -f "$container_macros"
}

###############################################################################
# Section 8: Argument parsing
###############################################################################

usage() {
    printf '%s\n' \
        "Usage: ${0##*/} [OPTIONS]" \
        '' \
        'Options:' \
        '  -h              Display this help' \
        '  -r              Convert to Rocky Linux via CIQ Depot' \
        '  -V              Verify switch (generate RPM lists before/after)' \
        '  -u USERNAME     CIQ Depot username (required)' \
        '  -p TOKEN        CIQ Depot token (required)' \
        '  -t TIER         Product tier: rlc-plus or rlc-pro (default: rlc-pro)' \
        '' \
        'Example:' \
        "  ${0##*/} -r -u myuser -p mytoken -t rlc-pro" >&2
    exit 1
}

###############################################################################
# Section 9: Main flow
###############################################################################

main() {
    local noopts=0
    while getopts "hrVu:p:t:" option; do
        (( noopts++ )) || true
        case "$option" in
            h) usage ;;
            r) convert_to_rocky=true ;;
            V) verify_all_rpms=true ;;
            u) depot_username="$OPTARG" ;;
            p) depot_token="$OPTARG" ;;
            t) depot_tier="$OPTARG" ;;
            *) errmsg 'Invalid switch\n'; usage ;;
        esac
    done
    if (( ! noopts )); then
        usage
    fi

    # Validate tier
    if [[ $depot_tier != "rlc-plus" && $depot_tier != "rlc-pro" ]]; then
        errmsg 'Invalid tier "%s". Must be rlc-plus or rlc-pro.\n' "$depot_tier"
        exit 1
    fi

    setup_logging
    infomsg 'migrate2rlc - Begin logging at %(%c)T.\n\n' -1

    # Set up temp dir
    tmp_dir=$(mktemp -d)
    trap exit_clean EXIT

    # Early checks
    efi_check
    detect_os
    validate_system

    # CIQ Depot credentials are required
    if [[ -z $depot_username || -z $depot_token ]]; then
        exit_message \
"CIQ Depot credentials are required.  Use -u USERNAME and -p TOKEN."
    fi
    check_depot

    if [[ ${verify_all_rpms:-} ]]; then
        generate_rpm_info begin
    fi

    if [[ ${convert_to_rocky:-} ]]; then
        # Remove dnf cache for clean slate
        infomsg 'Removing dnf cache...\n'
        dnf clean all 2>/dev/null
        rm -rf /var/cache/{yum,dnf}

        collect_efi_info
        collect_installed_removals
        collect_rocky_installs
        collect_modules
        establish_gpg_trust
        fix_dead_repos
        pre_update
        handle_stream_repos
        handle_subscription_manager
        swap_packages
        verify_swap
        configure_depot_repos
        disable_managed_repos
        restore_modules
        distro_sync
        install_kernel_if_needed
        fix_efi
        install_depot_cli
    fi

    if [[ ${verify_all_rpms:-} && ${convert_to_rocky:-} ]]; then
        generate_rpm_info finish
        infomsg $'\nYou may review the following files:\n'
        printf '%s\n' "${convert_info_dir}/${HOSTNAME}-rpm-list-"*.log
    fi

    printf '\n\n\n'
    if [[ ${convert_to_rocky:-} ]]; then
        infomsg $'\nDone, please reboot your system.\n'
    fi
    printf '%s%s%s\n' "$infocolor" \
        "A log of this installation can be found at $logfile" \
        "$nocolor" >&3 2>/dev/null || true

    exit 0
}

main "$@"
