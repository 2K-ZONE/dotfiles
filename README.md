# dotfiles

Managed with [chezmoi](https://www.chezmoi.io). The source repo lives in
`~/.local/share/chezmoi` (a normal git repo, not a bare one); chezmoi copies
the files into `$HOME`. File names in here map to targets:
`dot_zshrc` → `~/.zshrc`, `dot_config/zellij/config.kdl` → `~/.config/zellij/config.kdl`.

## New machine

```bash
# macOS / Linux: install chezmoi (or let tool-update.zsh do it later)
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
chezmoi init git@github.com:2K-ZONE/dotfiles.git   # https://github.com/2K-ZONE/dotfiles.git without a key
chezmoi diff     # review what would change in $HOME
chezmoi apply
```

```powershell
# Windows
winget install twpayne.chezmoi
chezmoi init https://github.com/2K-ZONE/dotfiles.git
chezmoi diff
chezmoi apply
```

## Daily use

| Task | Command |
|---|---|
| edit a managed file | `chezmoi edit ~/.zshrc` (applies on save with `--apply`) or edit in place, then `chezmoi re-add` |
| start managing a file | `chezmoi add ~/.config/foo/bar.conf` |
| see pending changes to `$HOME` | `chezmoi diff` / `chezmoi status` |
| commit and push | `chezmoi cd`, then plain `git add/commit/push` (normal completion) |
| pull and apply | `chezmoi update` (or wait for the weekly `dotfiles-update` check) |

## Per-OS files

`.chezmoiignore` is a template: Windows skips the zsh/tmux/kitty config,
macOS/Linux skip `AppData` and `Documents`.
