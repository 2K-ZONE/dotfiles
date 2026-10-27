# Weekly update check for starship and zellij, in the spirit of omz auto update.
#
# Settings (set before sourcing):
#   zstyle ':tool-update' mode prompt     # prompt | auto | disabled
#   zstyle ':tool-update' frequency 7     # days between checks
# Run `tool-update` to check right now.

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

# Run a command with sudo if the target directory is not writable.
_tool_update_priv() {
    local dir=$1; shift
    if [[ -w $dir ]]; then "$@"; else sudo "$@"; fi
}

_tool_update_starship() {
    local bindir=${commands[starship]:h}
    curl -fsSL --max-time 30 https://starship.rs/install.sh | sh -s -- -y -b $bindir
}

_tool_update_zellij() {
    local version=$1 bindir=${commands[zellij]:h} arch os tmp want have
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

tool-update() {
    local mode=$1 name repo current latest
    [[ -n $mode ]] || zstyle -s ':tool-update' mode mode || mode=prompt

    for name repo in starship starship/starship zellij zellij-org/zellij; do
        (( $+commands[$name] )) || continue
        current=${${(z)"$($name --version 2>/dev/null)"}[2]}
        latest=$(_tool_update_latest $repo) || {
            print -u2 "[$name] could not determine latest release"
            continue
        }
        is-at-least $latest $current && continue

        if [[ $mode == prompt ]]; then
            print -n "[$name] Update available: $current -> $latest. Update now? [Y/n] "
            read -r -k 1 REPLY
            [[ $REPLY == $'\n' ]] || print
            [[ $REPLY == [nN] ]] && continue
        else
            print "[$name] Updating $current -> $latest"
        fi

        if _tool_update_$name $latest; then
            print "[$name] Updated to $latest"
        else
            print -u2 "[$name] Update failed"
        fi
    done
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
    tool-update $mode
}
