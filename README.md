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

# Set up the hardware config file (Replace <HOST> with the right folder, e.g., perso)
nixos-generate-config --show-hardware-config > ~/nixos-config/hosts/<HOST>/hardware-configuration.nix

# For every file change, add it to git
git add .
(git config --global user.name "USERNAME")
(git config --global user.email "EMAIL")
git commit -m "added hardware config file" 

# FIRST INSTALLATION ONLY (nh is not installed yet)
# (--impure for the flake to link some dotfiles not to the nix store but to the give dotfile folder)
sudo nixos-rebuild switch --flake .#nixos-perso --impure 
```

**After the first installation, you can simply use:**
```bash
nh os switch . --impure
```

# Dotfiles / Config update 
Since `nh` is configured, you don't need to specify the flake path or run as `sudo` (it will ask for your password automatically if needed).

```bash
# To update the dotfiles input lock
nix flake update dotfiles

# To build and switch
nh os switch . --impure
```

# Garbage Collector

`nh` provides a much safer and cleaner garbage collector. 

```bash
# Clean everything that is not the current system
nh clean all

# Or to keep the last 3 generations and everything younger than 7 days:
nh clean all --keep 3 --keep-since 7d
```

# Optimise
Compact current libs

```bash
nix-store --optimise
```

# Analyze build

With `nh`, **builds are automatically analyzed and displayed beautifully!** `nh` natively uses `nix-output-monitor` (nom) under the hood. You will automatically see the tree representation and build times when you run `nh os switch`.

If you just want to build a configuration (like the homelab) to check for errors/analyze it *without* applying it:
```bash
nh os build .#nixos-homelab --impure
```

# For system update

Change this line in `flake.nix` to the right version :
```nix
nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
# Change also the home-manager "url" field to the right release
```

Do **NOT** change the line `system.stateVersion` !

Then simply use `nh`'s built-in update flag:
```bash
nh os switch . --update --impure
```
*(This automatically runs `nix flake update` and then builds/switches your system).*


# For SSH connection with bitwarden
1. open Bitwarden, connect, settings -> activate ssh agent
2. in ~/.ssh/config :
```
Host nixos-homelab
	HostName nixos-homelab
	User arthur
	IdentityAgent ~/.bitwarden-ssh-agent.sock
```