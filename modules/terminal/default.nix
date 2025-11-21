{ pkgs, ... }:

{
  # Install common terminal tools that you want on ALL your machines
  environment.systemPackages = with pkgs; [
    btop      # Modern resource monitor
    tree      # Directory listing tool
    nvitop    # GPU monitoring tool
    starship  # A nice cross-shell prompt (optional, configured via home-manager)
    htop
    killall
  ];

  # You could set a default system shell here if desired
  # programs.zsh.enable = true;
  # users.defaultUserShell = pkgs.zsh;
}