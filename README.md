# Install

With the setup script:
```bash
sudo sh ./setup.sh
```

Manually: 
```bash
# Clone the repo in /mnt/etc/nixos
git clone https://github.com/ArthurDelannoyazerty/nixos-config.git /mnt/etc/nixos

# Copy the hardwar file from /mnt/etc/niox to the wanted repo nixos config
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hosts/perso/

# Install the flake (the '#' tell nix the right config to install)
nixos-install --flake /mnt/etc/nixos#personal-desktop
```