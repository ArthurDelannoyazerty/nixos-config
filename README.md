# Install on a new machine

Install a fresh nixos system if not already done.

If not available, install `git` :
1. `sudo nano /etc/nixos/configuration.nix`
2. Add `git` to the field `environment.systemPackages`
3. Save, exit and type `sudo nixos-rebuild switch`


Then : 
```bash
sudo mv /etc/nixos /etc/nixos-backup

# Clone the repo in /mnt/etc/nixos
sudo git clone https://github.com/ArthurDelannoyazerty/nixos-config.git /etc/nixos

# IF NO HARDWARE CONFIG FILE : Copy the hardware file from /mnt/etc/niox to the wanted repo nixos config
sudo cp /etc/nixos-backup/hardware-configuration.nix /etc/nixos/hosts/perso/

cd /etc/nixos

# IF NO HARDWARE CONFIG FILE : add it to git
sudo git add .
(sudo git config --global user.name "USERNAME")
(sudo git config --global user.email "EMAIL")
sudo git commit -m "added hardware config file" 

# Install the flake (the '#' tell nix the right config to install)
sudo nixos-rebuild switch --flake .#perso
```