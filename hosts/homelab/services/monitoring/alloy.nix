# /hosts/homelab/services/monitoring/promtail.nix
{ config, pkgs, myConstants, ... }:

{
  # Enable Grafana Alloy to replace Promtail
  services.alloy = {
    enable = true;

    # (Optional) If you have external services checking Promtail's HTTP port, 
    # you can bind Alloy's UI/Metrics port to Promtail's old port. Otherwise it defaults to 12345.
    # extraFlags = [ "--server.http.listen-addr=0.0.0.0:${toString myConstants.services.promtail.port}" ];
  };

  # Alloy uses the "River" configuration language natively.
  # Injecting it via environment.etc allows NixOS to reload the service seamlessly on changes.
  environment.etc."alloy/config.alloy".text = ''
    // 1. Where to write logs (equivalent to Promtail's "clients")
    loki.write "default" {
      endpoint {
        url = "http://127.0.0.1:${toString myConstants.services.loki.port}/loki/api/v1/push"
      }
    }

    // 2. Relabeling rules (equivalent to Promtail's "relabel_configs")
    loki.relabel "journal" {
      forward_to = [loki.write.default.receiver]

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
    }

    // 3. Journal source (equivalent to Promtail's "scrape_configs")
    loki.source.journal "read" {
      forward_to = [loki.relabel.journal.receiver]
      max_age    = "12h"
      labels     = {
        "job"  = "systemd-journal",
        "host" = "${config.networking.hostName}",
      }
    }
  '';
}