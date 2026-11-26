# Weekly update check for starship, zellij and chezmoi, in the spirit of omz auto update.
#
# Settings (set before sourcing):
#   zstyle ':tool-update' mode prompt     # prompt | auto | disabled
#   zstyle ':tool-update' frequency 7     # days between checks
#   zstyle ':tool-update' bindir /usr/local/bin   # where missing tools go
#   zstyle ':tool-update' manual-mode auto  # auto | prompt, for `tool-update`
# Missing tools are offered for installation.
#
# Manual use, like `omz update`:
#   tool-update            update as set by manual-mode (default: no asking)
#   tool-update --check    only report available updates
#   tool-update --prompt   ask before each update

autoload -Uz is-at-least

_tool_update_stamp=${XDG_CACHE_HOME:-$HOME/.cache}/tool-update.stamp

# Latest release tag of a GitHub repo, without the leading "v".
# Follows the /releases/latest redirect, so no API rate limit applies.
_tool_update_latest() {
    local url
    url=$(curl -fsSIL -o /dev/null -w '%{url_effective}' --max-time 5 \
        "https://github.com/$1/releases/latest") || return 1
    [[ $url == */tag/* ]] || return 1
    print -r -- ${${url##*/}#v}
}

# Version number from `<tool> --version`, without "v" or trailing comma.
_tool_update_version() {
    local w
    for w in ${(z)"$($1 --version 2>/dev/null)"}; do
        w=${${w#v}%,}
        [[ $w == <->.<->* ]] && { print -r -- $w; return }
    done
}

# Run a command with sudo if the target directory is not writable.
_tool_update_priv() {
    local dir=$1; shift
    if [[ -w $dir ]]; then "$@"; else sudo "$@"; fi
}

_tool_update_starship() {
    local bindir=$2
    # The installer's stdout is mostly shell setup hints; errors go to stderr.
    curl -fsSL --max-time 30 https://starship.rs/install.sh | sh -s -- -y -b $bindir >/dev/null
}

_tool_update_zellij() {
    local version=$1 bindir=$2 arch os tmp want have
    case $(uname -m) in
        x86_64|amd64)  arch=x86_64 ;;
        arm64|aarch64) arch=aarch64 ;;
        *) print -u2 "zellij: unsupported architecture $(uname -m)"; return 1 ;;
    esac
    case $OSTYPE in
        darwin*) os=apple-darwin ;;
        linux*)  os=unknown-linux-musl ;;
        *) print -u2 "zellij: unsupported OS $OSTYPE"; return 1 ;;
    esac

    local base="https://github.com/zellij-org/zellij/releases/download/v$version/zellij-$arch-$os"
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/tool-update.XXXXXX") || return 1
    {
        curl -fsSL --max-time 120 -o $tmp/zellij.tar.gz $base.tar.gz &&
        curl -fsSL --max-time 30 -o $tmp/zellij.sha256sum $base.sha256sum &&
        tar -xzf $tmp/zellij.tar.gz -C $tmp zellij || return 1

        # The published checksum covers the binary, not the tarball.
        want=${${(z)"$(<$tmp/zellij.sha256sum)"}[1]}
        if (( $+commands[sha256sum] )); then
            have=${${(z)"$(sha256sum $tmp/zellij)"}[1]}
        else
            have=${${(z)"$(shasum -a 256 $tmp/zellij)"}[1]}
        fi
        if [[ $want != $have ]]; then
            print -u2 "zellij: checksum mismatch, not installing"
            return 1
        fi

        _tool_update_priv $bindir install -m 755 $tmp/zellij $bindir/zellij
    } always {
        rm -rf $tmp
    }
}

_tool_update_chezmoi() {
    local version=$1 bindir=$2 arch os tmp want have
    case $(uname -m) in
        x86_64|amd64)  arch=amd64 ;;
        arm64|aarch64) arch=arm64 ;;
        armv6l|armv7l) arch=armv6 ;;
        *) print -u2 "chezmoi: unsupported architecture $(uname -m)"; return 1 ;;
    esac
    case $OSTYPE in
        darwin*) os=darwin ;;
        linux*)  os=linux; [[ $arch == amd64 ]] && os=linux-musl ;;
        *) print -u2 "chezmoi: unsupported OS $OSTYPE"; return 1 ;;
    esac

    local file=chezmoi_${version}_${os}_$arch.tar.gz
    local base="https://github.com/twpayne/chezmoi/releases/download/v$version"
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/tool-update.XXXXXX") || return 1
    {
        curl -fsSL --max-time 120 -o $tmp/$file $base/$file &&
        curl -fsSL --max-time 30 -o $tmp/checksums.txt $base/chezmoi_${version}_checksums.txt ||
            return 1

        # Here the published checksum covers the tarball.
        want=${${(M)${(f)"$(<$tmp/checksums.txt)"}:#*  $file}%% *}
        if (( $+commands[sha256sum] )); then
            have=${${(z)"$(sha256sum $tmp/$file)"}[1]}
        else
            have=${${(z)"$(shasum -a 256 $tmp/$file)"}[1]}
        fi
        if [[ -z $want || $want != $have ]]; then
            print -u2 "chezmoi: checksum mismatch, not installing"
            return 1
        fi

        tar -xzf $tmp/$file -C $tmp chezmoi || return 1
        _tool_update_priv $bindir install -m 755 $tmp/chezmoi $bindir/chezmoi
    } always {
        rm -rf $tmp
    }
}

# $1: prompt | auto | check, $2: set to report tools that are up to date.
_tool_update_run() {
    local mode=$1 verbose=$2 name repo current latest bindir action

    for name repo in starship starship/starship zellij zellij-org/zellij \
                     chezmoi twpayne/chezmoi; do
        if (( $+commands[$name] )); then
            bindir=${commands[$name]:h}
            current=$(_tool_update_version $name)
        else
            zstyle -s ':tool-update' bindir bindir || bindir=/usr/local/bin
            current=
        fi

        latest=$(_tool_update_latest $repo) || {
            print -u2 "[$name] could not determine latest release"
            continue
        }
        if [[ -n $current ]] && is-at-least $latest $current; then
            [[ -n $verbose ]] && print "[$name] $current is up to date"
            continue
        fi

        if [[ $mode == check ]]; then
            print "[$name] ${current:-not installed} -> $latest available"
            continue
        fi

        if [[ -n $current ]]; then
            action="Update available: $current -> $latest. Update now?"
        else
            action="Not installed. Install $latest to $bindir?"
        fi
        if [[ $mode == prompt ]]; then
            print -n "[$name] $action [Y/n] "
            read -r -k 1 REPLY
            [[ $REPLY == $'\n' ]] || print
            [[ $REPLY == [nN] ]] && continue
        else
            print "[$name] Installing $latest to $bindir"
        fi

        if _tool_update_$name $latest $bindir; then
            rehash
            print "[$name] Installed $latest"
        else
            print -u2 "[$name] Installation failed"
        fi
    done
}

tool-update() {
    local mode
    case $1 in
        '')          zstyle -s ':tool-update' manual-mode mode || mode=auto ;;
        -c|--check)  mode=check ;;
        -p|--prompt) mode=prompt ;;
        -y|--yes)    mode=auto ;;
        -h|--help)
            print "usage: tool-update [--check|--prompt|--yes]"
            return ;;
        *)
            print -u2 "tool-update: unknown option $1"
            return 1 ;;
    esac

    # A manual run restarts the periodic check interval, as omz update does.
    if [[ $mode != check ]]; then
        zmodload -F zsh/datetime p:EPOCHSECONDS
        mkdir -p ${_tool_update_stamp:h}
        print $EPOCHSECONDS > $_tool_update_stamp
    fi
    _tool_update_run $mode 1
}

# Weekly check on interactive shell start-up.
() {
    local mode days
    zstyle -s ':tool-update' mode mode || mode=prompt
    zstyle -s ':tool-update' frequency days || days=7
    [[ $mode == disabled || ! -o interactive || ! -t 0 ]] && return

    zmodload -F zsh/datetime p:EPOCHSECONDS
    local last=0
    [[ -r $_tool_update_stamp ]] && last=$(<$_tool_update_stamp)
    (( EPOCHSECONDS - last >= days * 86400 )) || return

    # Write the stamp first so parallel shells don't all check at once.
    mkdir -p ${_tool_update_stamp:h}
    print $EPOCHSECONDS > $_tool_update_stamp
    _tool_update_run $mode
}
