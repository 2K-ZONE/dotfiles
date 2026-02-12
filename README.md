# Initial setup (on your first machine)
git init --bare $HOME/.dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfiles config --local status.showUntrackedFiles no

```bash
git init --bare $HOME/.dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfiles add ~/.zshrc
dotfiles commit -m "Initial dotfiles"
```


# Add your config files
dotfiles add ~/.config/kitty/kitty.conf
dotfiles add ~/.config/starship.toml
dotfiles add ~/.config/zellij/config.kdl
dotfiles commit -m "Add config files"
dotfiles remote add origin git@github.com:yourusername/dotfiles.git
dotfiles push -u origin main



# On a new machine — clone and restore
git clone --bare git@github.com:yourusername/dotfiles.git $HOME/.dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfiles checkout


echo "alias dotfiles='git --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME'" >> ~/.zshrc%                                                                                    
```bash
git init --bare $HOME/.dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfiles add ~/.zshrc
dotfiles commit -m "Initial dotfiles"
``````bash
git init --bare $HOME/.dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfiles add ~/.zshrc
dotfiles commit -m "Initial dotfiles"
```
