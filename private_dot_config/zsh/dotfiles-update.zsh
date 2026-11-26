# Weekly dotfiles update via chezmoi, in the spirit of omz auto update.
#
# Settings (set before sourcing):
#   zstyle ':dotfiles-update' mode prompt     # prompt | auto | disabled
#   zstyle ':dotfiles-update' frequency 7     # days between checks
# Only fast-forwards are pulled; a diverged repo is reported, not merged.
# After pulling, `chezmoi apply` writes the changes to $HOME. It asks before
# overwriting a file you changed locally since its last apply.
# Run `dotfiles-update` to check right now.

_dotfiles_update_stamp=${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-update.stamp

dotfiles-update() {
    local mode=$1 src behind ahead
    [[ -n $mode ]] || zstyle -s ':dotfiles-update' mode mode || mode=prompt
    (( $+commands[chezmoi] )) || return 0
    src=$(chezmoi source-path 2>/dev/null) && [[ -d $src/.git ]] || return 0

    # BatchMode: never hang the shell start-up on a passphrase or host key prompt.
    GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=5" \
        git -C $src fetch --quiet 2>/dev/null || {
        print -u2 "[dotfiles] fetch failed, skipping"
        return 1
    }

    behind=$(git -C $src rev-list --count HEAD..@{upstream} 2>/dev/null) || return 1
    ahead=$(git -C $src rev-list --count @{upstream}..HEAD 2>/dev/null) || return 1
    (( behind )) || return 0

    if (( ahead )); then
        print -u2 "[dotfiles] diverged ($ahead local, $behind remote commits), pull manually in 'chezmoi cd'"
        return 1
    fi

    if [[ $mode == prompt ]]; then
        print -n "[dotfiles] $behind new commit(s). Update now? [Y/n] "
        read -r -k 1 REPLY
        [[ $REPLY == $'\n' ]] || print
        [[ $REPLY == [nN] ]] && return 0
    else
        print "[dotfiles] Pulling $behind new commit(s)"
    fi

    local old=$(git -C $src rev-parse HEAD)
    if git -C $src pull --ff-only --quiet; then
        # Like omz after an update: what came in, without a pager.
        git -C $src --no-pager log --oneline $old..HEAD
        git -C $src --no-pager diff --stat $old HEAD
    else
        print -u2 "[dotfiles] Pull failed"
        return 1
    fi

    if chezmoi apply; then
        print "[dotfiles] Updated, run 'exec zsh' to load changed shell config"
    else
        print -u2 "[dotfiles] chezmoi apply failed, see 'chezmoi diff'"
        return 1
    fi
}

# Weekly check on interactive shell start-up.
() {
    local mode days
    zstyle -s ':dotfiles-update' mode mode || mode=prompt
    zstyle -s ':dotfiles-update' frequency days || days=7
    [[ $mode == disabled || ! -o interactive || ! -t 0 ]] && return

    zmodload -F zsh/datetime p:EPOCHSECONDS
    local last=0
    [[ -r $_dotfiles_update_stamp ]] && last=$(<$_dotfiles_update_stamp)
    (( EPOCHSECONDS - last >= days * 86400 )) || return

    # Write the stamp first so parallel shells don't all check at once.
    mkdir -p ${_dotfiles_update_stamp:h}
    print $EPOCHSECONDS > $_dotfiles_update_stamp
    dotfiles-update $mode
}
