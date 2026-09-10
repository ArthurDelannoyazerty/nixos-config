# Devcontainer

Workspace Nix non-root (`arthur`, UID/GID 999) pour VS Code + Kubernetes.

Le `$HOME` et `/nix` sont persistants. Les outils ponctuels peuvent donc être installés sans reconstruire l'image.

```bash
# Temporaire
nix shell nixpkgs#just

# Persistant
nix profile install nixpkgs#just
```

## Files

```text
hosts/devcontainer/
├── default.nix
├── README_DEVCONTAINER.md
├── scripts/
│   ├── entrypoint.sh
│   ├── seed-nix.sh
│   ├── sync-dotfiles.sh
│   ├── install-extensions.sh
│   ├── doctor.sh
│   └── with-gpu-libs.sh
└── k8s/
    ├── deployment-minimal.yaml
    └── deployment-gpu.yaml
```

`default.nix` construit l'image. `seed-nix.sh` initialise le `/nix` persistant. `entrypoint.sh` prépare le workspace et synchronise les dotfiles. `doctor.sh` vérifie rapidement l'environnement.

Les dotfiles sont automatiquement clonés/mis à jour depuis:`https://github.com/ArthurDelannoyazerty/dotfiles` Ils vivent dans `~/dotfiles`et ne sont pas inclus dans l'image.

Après la première connexion VS Code:

```bash
devcontainer-install-extensions
```

La commande utilise `~/dotfiles/code/extensions.txt` et peut être relancée sans problème.

Si `setup.sh` du repo dotfiles change ses liens:

```bash
bash ~/dotfiles/setup.sh
```

Update dotfiles :

```bash
devcontainer-sync-dotfiles
```

Diagnostic:

```bash
devcontainer-doctor
```

# Available nix commands

Because the container has a persistent writable `/nix`, the useful Nix workflow is quite broad.

```bash
# For temporary use
nix shell nixpkgs#htop

# For executing command without entering the shell
nix shell nixpkgs#jq -c jq --version

# To install something permanently
nix profile install nixpkgs#htop

# To see what is installed
nix profile list

# To remove something
nix profile remove htop
```



# Deployement

> Anyone entering the pod as `arthur` has access to everything readable/writable by `arthur`. The Kubernetes security context protects the cluster, not the contents of Arthur's home directory.

Deploy using the `.yaml` files in `./hosts/devcontainer/k8s` 

