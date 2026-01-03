{ config, pkgs, inputs, ... }:

let
  serviceName = "local-finance";
  servicePort = 8501;
  
  # The source code comes from flake inputs
  src = inputs.local-finance;

  # We generate the Dockerfile here to ensure it uses uv
  dockerfile = pkgs.writeText "Dockerfile" ''
    # Use the official image which includes uv and python
    FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

    WORKDIR /app

    # Install system dependencies (if needed for compiling python libs)
    RUN apt-get update && apt-get install -y gcc && rm -rf /var/lib/apt/lists/*

    # Copy files
    # We copy everything because we are building from a clean source input
    COPY . .

    # Use uv to install dependencies into a system-wide environment (since it's a container)
    # We check if uv.lock exists, otherwise we just use pyproject.toml
    RUN uv pip install --system -r pyproject.toml || uv pip install --system .

    # replace classic polar with long term support because old pc
    RUN uv pip uninstall --system polars
    RUN uv pip install --system polars[rtcompat]

    EXPOSE ${toString servicePort}

    # Run Streamlit
    CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0", "--server.port=${toString servicePort}"]
  '';

in
{
  # 1. Open Firewall for this specific service
  networking.firewall.allowedTCPPorts = [ servicePort ];

  # 2. Systemd Service to Build the Image
  #    This runs before the container starts. It copies the flake source + our Dockerfile
  #    to a temp folder and builds the image.
  systemd.services."build-${serviceName}-image" = {
    description = "Build Docker image for ${serviceName}";
    before = [ "docker-${serviceName}.service" ];
    requiredBy = [ "docker-${serviceName}.service" ];
    script = ''
      # Create a temporary build context
      BUILD_DIR=$(mktemp -d)
      
      # Copy the source code from the Nix Store (Input) to temp dir
      # We need read/write access for Docker build context
      cp -r ${src}/* $BUILD_DIR/
      
      # Copy our generated Dockerfile into the build dir
      cp ${dockerfile} $BUILD_DIR/Dockerfile
      
      # Build the image
      ${pkgs.docker}/bin/docker build -t ${serviceName}:latest $BUILD_DIR
      
      # Cleanup
      rm -rf $BUILD_DIR
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  # 3. The Container
  virtualisation.oci-containers.containers."${serviceName}" = {
    image = "${serviceName}:latest";
    ports = [ "${toString servicePort}:${toString servicePort}" ];
    volumes = [
      # Mount a data directory if your app writes to a local SQLite file
      "/var/lib/${serviceName}/data:/app/data"
    ];
    extraOptions = [
      "--pull=never"  # Force using the locally built image
    ];
  };
  
  # Ensure the data directory exists on the host
  systemd.tmpfiles.rules = [
    "d /var/lib/${serviceName}/data 0777 root root -"
  ];
}