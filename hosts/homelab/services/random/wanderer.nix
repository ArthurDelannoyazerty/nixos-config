{ config, pkgs, myConstants, ... }:

let
  cenv = {
    MEILI_URL = "http://172.17.0.1:${toString myConstants.services.wanderer-search.port}";
  };
  
  secretEnvFile = "${myConstants.paths.servicesSSD}/wanderer/.env";
in
{
  virtualisation.oci-containers.containers.${myConstants.services.wanderer-search.containerName} = {
    image = "getmeili/meilisearch:${myConstants.services.wanderer-search.version}";
    ports =[ (myConstants.bind myConstants.services.wanderer-search.port) ];
    
    environmentFiles = [ secretEnvFile ];
    
    environment = cenv // {
      MEILI_NO_ANALYTICS = "true";
    };
    volumes =[
      "${myConstants.paths.servicesSSD}/wanderer/meili_data:/meili_data/data.ms"
    ];
  };

  virtualisation.oci-containers.containers.${myConstants.services.wanderer-db.containerName} = {
    image = "flomp/wanderer-db:${myConstants.services.wanderer-db.version}";
    ports =[ (myConstants.bind myConstants.services.wanderer-db.port) ];

    dependsOn = [ myConstants.services.wanderer-search.containerName ];
    
    environmentFiles =[ secretEnvFile ];

    environment = cenv // {
      ORIGIN = "https://${myConstants.services.wanderer.subdomain}.${myConstants.publicDomain}";
    };
    volumes =[
      "${myConstants.paths.servicesSSD}/wanderer/pb_data_new:/pb_data"
    ];
  };

  virtualisation.oci-containers.containers.${myConstants.services.wanderer.containerName} = {
    image = "flomp/wanderer-web:${myConstants.services.wanderer.version}";
    ports =[ "0.0.0.0:${toString myConstants.services.wanderer.port}:3000" ];
    
    dependsOn = [ myConstants.services.wanderer-db.containerName ];
    
    environmentFiles = [ secretEnvFile ];

    environment = cenv // {
      ORIGIN = "https://${myConstants.services.wanderer.subdomain}.${myConstants.publicDomain}";
      
      BODY_SIZE_LIMIT = "Infinity";
      PUBLIC_POCKETBASE_URL = "https://${myConstants.services.wanderer-db.subdomain}.${myConstants.publicDomain}";
      
      # Hide the signup form, users MUST use Authentik SSO
      PUBLIC_DISABLE_SIGNUP = "true"; 
      
      UPLOAD_FOLDER = "/app/uploads";
      PUBLIC_VALHALLA_URL = "https://valhalla1.openstreetmap.de";
      PUBLIC_NOMINATIM_URL = "https://nominatim.openstreetmap.org";
    };
    volumes =[
      "${myConstants.paths.servicesSSD}/wanderer/uploads:/app/uploads"
    ];

  };
}