# For devcontainer
To create the docker image, use the github action.

The first time your start the container, execute `sh /bin/setup_devcontainer.sh` to init the dotfiles and install the vscode extensions.

# Install on a new machine

Install a fresh nixos system if not already done.

Connect to wifi :
```bash
nmcli device
nmcli connection show
nmcli radio
nmcli device wifi list
sudo nmcli device wifi connect "SSID_Name" password "Your_Password"
```

If not available, install `git` :
1. `sudo nano /etc/nixos/configuration.nix`
2. Add `git` to the field `environment.systemPackages`
3. Save, exit and type `sudo nixos-rebuild switch`

You can first set up your dotfiles so the following impure flake can link them easily : https://github.com/ArthurDelannoyazerty/dotfiles (wihout executing the setup.sh, nixos is taking care of that)


Then : 
```bash
# Clone the repo
cd ~
git clone https://github.com/ArthurDelannoyazerty/nixos-config.git
cd nixos-config

# Set up the hardware config file
nixos-generate-config --show-hardware-config > ~/nixos-config/hosts/<HOST>/hardware-configuration.nix

# For every file change, add it to git
git add .
(git config --global user.name "USERNAME")
(git config --global user.email "EMAIL")
git commit -m "added hardware config file" 

# Install the flake (the '#' tell nix the right config to install) 
# (--impure for the flake to link some dotfiles not to the nix store but to the give dotfile folder)
sudo nixos-rebuild switch --flake .#perso --impure 
```

# Dotfiles update 
```bash
cd ~/nixos-config
sudo nix flake update dotfiles
sudo nixos-rebuild switch --flake .#perso --impure
```

# Garbage Collector

```bash
sudo nix-collect-garbage -d
```

# Optimise
Compact current libs

```bash
nix-store --optimise
```
