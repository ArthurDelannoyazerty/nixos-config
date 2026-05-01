{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers.${myConstants.services.stirling-pdf.containerName} = {
    image = "stirlingtools/stirling-pdf:${myConstants.services.stirling-pdf.version}";
    
    ports =[ "127.0.0.1:${toString myConstants.services.stirling-pdf.port}:8080" ];
    
    environment = {
      DOCKER_ENABLE_SECURITY = "false";
      
      LANGS = "en_GB,fr_FR";
      SYSTEM_DEFAULTLOCALE = "fr-FR";
      UI_APPNAME = "Homelab PDF Suite";
    };

    volumes =[
      "${myConstants.paths.servicesSSD}/stirling-pdf/trainingData:/usr/share/tesseract-ocr/5.00/tessdata"
      "${myConstants.paths.servicesSSD}/stirling-pdf/extraConfigs:/configs"
      "${myConstants.paths.servicesSSD}/stirling-pdf/customFiles:/customFiles"
    ];
  };
}