# /modules/home-manager/vscode.nix
{ pkgs, inputs, ... }:

let
  marketplace = pkgs.vscode-marketplace;
in
{


programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = true; 

    profiles.default.extensions = with marketplace; [
      # === PYTHON ===
      ms-python.python
      ms-python.debugpy
      ms-python.vscode-pylance
      ms-python.vscode-python-envs
      charliermarsh.ruff
      njpwerner.autodocstring
      njqdev.vscode-python-typehint
      ms-toolsai.jupyter
      ms-toolsai.jupyter-keymap
      ms-toolsai.jupyter-renderers
      ms-toolsai.vscode-jupyter-cell-tags
      
      # === AI ===
      continue.continue
      google.geminicodeassist
      
      # === REMOTE & SSH ===
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      ms-vscode.remote-explorer
      ms-vscode.remote-repositories
      ms-azuretools.vscode-containers

      # === GIT ===
      eamodio.gitlens
      mhutchie.git-graph
      ms-vscode.azure-repos

      # === THEMES & ICONS ===
      pkief.material-icon-theme
      monokai.theme-monokai-pro-vscode
      nicolaiverbaarschot.alabaster-variant-theme
      tonsky.theme-alabaster
      johnpapa.vscode-peacock

      # === TOOLS ===
      esbenp.prettier-vscode
      mechatroner.rainbow-csv
      hediet.vscode-drawio
      mermaidchart.vscode-mermaid-chart
      jnoortheen.nix-ide
      christian-kohler.path-intellisense
      ritwickdey.liveserver
      tomoki1207.pdf
      stackbreak.comment-divider
      torreysmith.copyfilepathandcontent
      irongeek.vscode-env
      emilast.logfilehighlighter
      alexcvzz.vscode-sqlite
      qwtel.sqlite-viewer
      rioj7.command-variable
      
      # === MISC ===
      codediagram.codediagram 
      marketplace."076923".python-image-preview 
    ];
  };

}