# Install on a new machine

Install a fresh nixos system if not already done.

If not available, install `git` :
1. `sudo nano /etc/nixos/configuration.nix`
2. Add `git` to the field `environment.systemPackages`
3. Save, exit and type `sudo nixos-rebuild switch`


Then : 
```bash
# Backup original nixos config
sudo mv /etc/nixos /etc/nixos-backup

# Clone the repo
cd ~
sudo git clone https://github.com/ArthurDelannoyazerty/nixos-config.git
cd nixos-config

# IF NO HARDWARE CONFIG FILE IN "hosts/<HOST>/", then copy the hardware file to the right host
sudo cp /etc/nixos-backup/hardware-configuration.nix ~/nixos-config/hosts/<HOST>/

# For every file change, add it to git
sudo git add .
(sudo git config --global user.name "USERNAME")
(sudo git config --global user.email "EMAIL")
sudo git commit -m "added hardware config file" 

# Install the flake (the '#' tell nix the right config to install)
sudo nixos-rebuild switch --flake .#perso
```

If you udpate the dotfile, then update it in your pc with : 
```bash
cd ~/nixos-config
sudo nix flake update dotfiles
sudo nixos-rebuild switch --flake .#perso
```