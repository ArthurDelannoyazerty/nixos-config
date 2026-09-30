{ config, pkgs, myConstants, ... }:

let
  litellmConfig = pkgs.writeText "litellm-config.yaml" ''
    # Models are intentionally managed from the LiteLLM UI / database.
    model_list: []

    general_settings:
      master_key: os.environ/LITELLM_MASTER_KEY
  '';
in
{
  # ---------------------------------------------------------------------------
  # PostgreSQL
  # ---------------------------------------------------------------------------

  virtualisation.oci-containers.containers.${myConstants.services.litellm-db.containerName} = {
    image = "postgres:${myConstants.services.litellm-db.version}";

    environmentFiles = [
      "${myConstants.paths.servicesSSD}/litellm/postgres.env"
    ];

    volumes = [
      "${myConstants.paths.servicesSSD}/litellm/postgres:/var/lib/postgresql/data"
    ];
  };


  # ---------------------------------------------------------------------------
  # LiteLLM
  # ---------------------------------------------------------------------------

  virtualisation.oci-containers.containers.${myConstants.services.litellm.containerName} = {
    image = "ghcr.io/berriai/litellm:${myConstants.services.litellm.version}";

    # Important: only Caddy should access this port directly.
    ports = [
      "127.0.0.1:${toString myConstants.services.litellm.port}:${toString myConstants.services.litellm.port}"
    ];

    environment = {
      # Persist models created in the UI.
      STORE_MODEL_IN_DB = "True";

      # External URL used for OIDC callbacks.
      PROXY_BASE_URL = "https://${myConstants.services.litellm.subdomain}.${myConstants.publicDomain}";

      # Authentik OIDC
      GENERIC_AUTHORIZATION_ENDPOINT = "https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}/application/o/authorize/";
      GENERIC_TOKEN_ENDPOINT = "https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}/application/o/token/";
      GENERIC_USERINFO_ENDPOINT = "https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}/application/o/userinfo/";
      GENERIC_SCOPE = "openid profile email";

      # Use OIDC's stable account identifier.
      GENERIC_USER_ID_ATTRIBUTE = "sub";
      GENERIC_USER_EMAIL_ATTRIBUTE = "email";
      GENERIC_USER_DISPLAY_NAME_ATTRIBUTE = "name";
      GENERIC_USER_FIRST_NAME_ATTRIBUTE = "given_name";
      GENERIC_USER_LAST_NAME_ATTRIBUTE = "family_name";

      GENERIC_CLIENT_USE_PKCE = "true";

      # Put Swagger somewhere explicit and make / open the UI.
      DOCS_URL = "/docs";
      ROOT_REDIRECT_URL = "/ui";
    };

    environmentFiles = [
      "${myConstants.paths.servicesSSD}/litellm/litellm.env"
    ];

    volumes = [
      "${litellmConfig}:/app/config.yaml:ro"
    ];

    cmd = [
      "--config"
      "/app/config.yaml"
    ];

    dependsOn = [
      myConstants.services.litellm-db.containerName
    ];

    # Your setup currently uses Docker's default bridge, so give the DB
    # a stable hostname without publishing PostgreSQL on the host.
    extraOptions = [
      "--link=${myConstants.services.litellm-db.containerName}:litellm-db"
    ];
  };
}