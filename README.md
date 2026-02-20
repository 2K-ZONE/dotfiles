# Initial setup (on your first machine)
```bash
git init --bare $HOME/.dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfiles add ~/.zshrc
dotfiles commit -m "Initial dotfiles"
```

# Add your config files
```bash
dotfiles add ~/.config/kitty/kitty.conf
dotfiles add ~/.config/starship.toml
dotfiles add ~/.config/zellij/config.kdl
dotfiles commit -m "Add config files"
dotfiles remote add origin git@github.com:2K-ZONE/dotfiles.git
dotfiles push -u origin main
```

# On a new machine — clone and restore
```bash
git clone --bare https://github.com/2K-ZONE/dotfiles.git $HOME/.dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfiles checkout
```

```bash
echo "alias dotfiles='git --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME'" >> ~/.zshrc%                                                                                    
```



# Yes! You Can Be Selective
## Pull Only Specific Files

```bash
# After cloning the bare repo on a new PC
git clone --bare https://github.com/2K-ZONE/dotfiles.git $HOME/.dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfiles config --local status.showUntrackedFiles no
```
```bash
# Checkout only specific files
dotfiles checkout -- ~/.config/kitty/kitty.conf
dotfiles checkout -- ~/.zshrc
```

# See What's Available
```bash
dotfiles ls-tree --name-only -r main
```

# Add More Later
## On any machine
```bash
dotfiles checkout -- ~/.config/starship.toml
```






