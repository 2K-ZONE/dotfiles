# Weekly `dotfiles pull`, in the spirit of omz auto update.
#
# Settings (set before sourcing):
#   zstyle ':dotfiles-update' mode prompt     # prompt | auto | disabled
#   zstyle ':dotfiles-update' frequency 7     # days between checks
# Only fast-forwards are pulled; a diverged repo is reported, not merged.
# Run `dotfiles-update` to check right now.

_dotfiles_update_stamp=${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-update.stamp

_dotfiles_git() {
    git --git-dir=$HOME/.dotfiles --work-tree=$HOME "$@"
}

dotfiles-update() {
    local mode=$1 behind ahead
    [[ -n $mode ]] || zstyle -s ':dotfiles-update' mode mode || mode=prompt
    [[ -d $HOME/.dotfiles ]] || return 0

    # A bare clone has no fetch refspec, so fetch would create no origin/*.
    _dotfiles_git config --get remote.origin.fetch >/dev/null ||
        _dotfiles_git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'

    # BatchMode: never hang the shell start-up on a passphrase or host key prompt.
    GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=5" \
        _dotfiles_git fetch --quiet 2>/dev/null || {
        print -u2 "[dotfiles] fetch failed, skipping"
        return 1
    }

    # ...and its branch has no upstream either.
    if ! _dotfiles_git rev-parse -q --verify @{upstream} >/dev/null 2>&1; then
        local branch=$(_dotfiles_git symbolic-ref -q --short HEAD)
        _dotfiles_git branch -q -u origin/$branch $branch 2>/dev/null || {
            print -u2 "[dotfiles] no upstream for '$branch', skipping"
            return 1
        }
        print "[dotfiles] Set upstream of '$branch' to origin/$branch"
    fi

    behind=$(_dotfiles_git rev-list --count HEAD..@{upstream} 2>/dev/null) || return 1
    ahead=$(_dotfiles_git rev-list --count @{upstream}..HEAD 2>/dev/null) || return 1
    (( behind )) || return 0

    if (( ahead )); then
        print -u2 "[dotfiles] diverged ($ahead local, $behind remote commits), pull manually"
        return 1
    fi

    if [[ $mode == prompt ]]; then
        _dotfiles_git log --oneline HEAD..@{upstream}
        print -n "[dotfiles] $behind new commit(s). Pull now? [Y/n] "
        read -r -k 1 REPLY
        [[ $REPLY == $'\n' ]] || print
        [[ $REPLY == [nN] ]] && return 0
    else
        print "[dotfiles] Pulling $behind new commit(s)"
    fi

    if _dotfiles_git pull --ff-only --quiet; then
        print "[dotfiles] Updated, run 'exec zsh' to load changed shell config"
    else
        print -u2 "[dotfiles] Pull failed"
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
