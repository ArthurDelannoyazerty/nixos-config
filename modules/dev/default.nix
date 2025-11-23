{ pkgs, ... }:

{
  # =========================================================================
  # == CORE DEVELOPMENT TOOLS
  # =========================================================================

  environment.systemPackages = with pkgs; [
    # --- Essentials ---
    git       # Version control is non-negotiable
    gcc       # C compiler, needed by many tools and libraries
    gnumake   # The standard build tool

    # --- Nix Language Support ---
    nixpkgs-fmt # Formatter for your Nix code, helps keep it clean
  ]
  ++
  # =========================================================================
  # == PYTHON DEVELOPMENT
  #    Using `uv` for modern, fast package and virtual environment management.
  # =========================================================================

  [
    python3   # A system-wide Python interpreter
    uv        # The extremely fast Python package installer and resolver
  ]
  ++
  # =========================================================================
  # == JAVA DEVELOPMENT
  #    Installs a Java Development Kit (JDK).
  # =========================================================================

  [
    # We install the latest Long-Term Support (LTS) version of OpenJDK.
    jdk21

    # If you need a different version, simply change the package name.
    # Common options include: jdk17, jdk11, jdk8
  ];

  # =========================================================================
  # == CONTAINERIZATION (DOCKER)
  #    Enables the Docker daemon and adds your user to the group.
  # =========================================================================

  # Enable the Docker virtualisation service
  virtualisation.docker.enable = true;
  
  # Add your user to the 'docker' group to allow running docker commands
  # without needing to use `sudo`.
  users.groups.docker.members = [ "arthur" ];
}