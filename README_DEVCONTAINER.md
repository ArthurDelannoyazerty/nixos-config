# Devcontainer

Non-root Nix workspace (`arthur`, UID/GID 999) for VS Code + Kubernetes.

`$HOME` and `/nix` are persistent, so tools can be installed without rebuilding the image.


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

`default.nix` builds the image.
`seed-nix.sh` initializes the persistent `/nix` store.
`entrypoint.sh` prepares the workspace and updates the dotfiles.
`doctor.sh` performs basic environment checks.

Dotfiles are automatically cloned/updated from `https://github.com/ArthurDelannoyazerty/dotfiles`. They live in `~/dotfiles` and are not included in this repository.

After the first VS Code connection:

```bash
devcontainer-install-extensions
```

This installs extensions from `~/dotfiles/code/extensions.txt` and can safely be rerun.

Update dotfiles manually:

```bash
devcontainer-sync-dotfiles
```

If `setup.sh` changes its symlink configuration:

```bash
bash ~/dotfiles/setup.sh
```

Diagnostic:

```bash
devcontainer-doctor
```

## Useful Nix commands

```bash
# Temporary environment
nix shell nixpkgs#htop

# Run a command without entering a shell
nix shell nixpkgs#jq -c jq --version

# Install into the persistent user profile
nix profile install nixpkgs#htop

# List installed profile packages
nix profile list

# Remove a profile package
nix profile remove htop
```

For projects providing a Nix flake:

```bash
nix develop
```

Do not use `nixos-rebuild` or `systemctl`: this is a Nix-based container, not a booted NixOS system.

## Deployment

> Anyone entering the pod as `arthur` has access to everything readable/writable by `arthur`. The Kubernetes security context protects the cluster/node, not Arthur's home directory.

Deploy **one** of the manifests in `hosts/devcontainer/k8s/`:

* `deployment-minimal.yaml`: generic workspace.
* `deployment-gpu.yaml`: NVIDIA GPU workspace.

Do not run both simultaneously: they use the same persistent home and Nix store.


## VSCode connection

- Use the kubernetes and the devcontainer extensions
- Be sure to have a kubeconfig file from the k8s cluster (windows location: `C:\Users\USER\.kube\config` or `C:\profils\USER\.kube\rancher-local.yaml`) (Check `echo %KUBECONFIG%` to see what VSCode use)
- 
