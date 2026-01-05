# /modules/services/local-finance/local-finance.nix

{ config, pkgs, inputs, myConstants, ... }:

let
  serviceName = "local-finance";
  servicePort = myConstants.services.finance.port;
  
  # The source code comes from flake inputs
  src = inputs.local-finance;

  # We generate the Dockerfile here to ensure it uses uv
  dockerfile = pkgs.writeText "Dockerfile" ''
    FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim
    WORKDIR /app

    # Install system dependencies (if needed for compiling python libs)
    RUN apt-get update && apt-get install -y gcc && rm -rf /var/lib/apt/lists/*
    COPY . .
    RUN uv pip install --system -r pyproject.toml || uv pip install --system .

    # replace classic polar with long term support because old pc
    RUN uv pip uninstall --system polars
    RUN uv pip install --system polars[rtcompat]
    EXPOSE ${toString servicePort}
    CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0", "--server.port=${toString servicePort}"]
  '';

in
{
  systemd.services."build-${serviceName}-image" = {
    description = "Build Docker image for ${serviceName}";
    before = [ "docker-${serviceName}.service" ];
    requiredBy = [ "docker-${serviceName}.service" ];
    
    # Increase timeout to allow long builds when they ARE needed
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      TimeoutStartSec = "1600";
    };

    path = with pkgs; [ docker coreutils bash ];

    script = ''
      # 1. Get the unique Hash of the source code from the Nix Store path
      # Example path: /nix/store/xm35...-source
      SRC_PATH="${src}"
      SRC_NAME=$(basename "$SRC_PATH")
      # Extract just the hash part (everything before the first dash)
      SRC_HASH=''${SRC_NAME%%-*}
      
      # Define a unique tag for this version of the code
      IMAGE_TAG="${serviceName}:$SRC_HASH"
      
      echo "Checking for image: $IMAGE_TAG"

      # 2. Check if we have already built this exact version
      if docker image inspect "$IMAGE_TAG" > /dev/null 2>&1; then
          echo "✅ Cache Hit! Image $IMAGE_TAG exists."
          echo "Skipping rebuild."
      else
          echo "⚡ Cache Miss! Building new image..."
          
          # Create temp dir
          BUILD_DIR=$(mktemp -d)
          
          # Copy source and Dockerfile
          cp -r $SRC_PATH/* $BUILD_DIR/
          cp ${dockerfile} $BUILD_DIR/Dockerfile
          
          # Build it and tag it with the hash
          docker build -t "$IMAGE_TAG" $BUILD_DIR
          
          # Cleanup
          rm -rf $BUILD_DIR
      fi
      
      # 3. Always tag this specific version as 'latest' so the container finds it
      docker tag "$IMAGE_TAG" ${serviceName}:latest
      echo "Tagged $IMAGE_TAG as ${serviceName}:latest"
    '';
  };

  virtualisation.oci-containers.containers."${serviceName}" = {
    image = "${serviceName}:latest";
    ports = [ (myConstants.bind servicePort) ];
    volumes = [ "/var/lib/${serviceName}/data:/app/data" ];
    extraOptions = [ "--pull=never" ];
  };
  
  systemd.tmpfiles.rules = [
    "d /var/lib/${serviceName}/data 0777 root root -"
  ];
}