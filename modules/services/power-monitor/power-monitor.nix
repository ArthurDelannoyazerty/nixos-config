{ config, pkgs, ... }:

let
  # Adjustable Settings
  port = 9100;
  kwhPrice = 0.22; # Approx price in France (€/kWh)
  idleOffset = 15; # Estimated watts for Mobo/SSD/Fans not measured by CPU sensor

  powerScript = pkgs.writeScriptBin "power-monitor" ''
    #!${pkgs.python3}/bin/python3
    import http.server
    import socketserver
    import time
    import json
    import os

    # Path to Intel RAPL (Running Average Power Limit) sensor
    # rapl:0 is usually the "package-0" (CPU + integrated graphics + memory controller)
    RAPL_PATH = "/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj"
    
    current_watts = 0

    def read_energy():
        try:
            with open(RAPL_PATH, "r") as f:
                return int(f.read())
        except:
            return 0

    # Background thread logic simulated in request for simplicity
    # Ideally we compare two reads with a known time delta
    def get_instant_watts():
        t1 = time.time()
        e1 = read_energy()
        time.sleep(0.2) # Short pause to measure delta
        t2 = time.time()
        e2 = read_energy()
        
        # Energy is in microjoules. 1 Joule/sec = 1 Watt
        # (e2 - e1) / 1000000 / (t2 - t1)
        joules_delta = (e2 - e1) / 1_000_000
        time_delta = t2 - t1
        return joules_delta / time_delta

    class Handler(http.server.SimpleHTTPRequestHandler):
        def do_GET(self):
            # Calculate metrics
            cpu_watts = get_instant_watts()
            total_watts = cpu_watts + ${toString idleOffset}
            
            # Monthly Cost: (Watts / 1000) * Price * 24h * 30d
            monthly_cost = (total_watts / 1000) * ${toString kwhPrice} * 24 * 30

            # Homepage Custom API Format
            # We can use 'fields' to display multiple stats
            data = {
                "fields": [
                    { "name": "Usage", "value": f"{total_watts:.1f} W" },
                    { "name": "Cost", "value": f"{monthly_cost:.2f}€ /mo" }
                ]
            }

            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())

    # Allow port reuse
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", ${toString port}), Handler) as httpd:
        print(f"Serving power stats on port ${toString port}")
        httpd.serve_forever()
  '';
in
{
  # 1. Load Kernel Modules for Sensors
  boot.kernelModules = [ "msr" "powercap" "intel_rapl_common" ];

  # 2. Open Firewall
  networking.firewall.allowedTCPPorts = [ port ];

  # 3. Create the Service
  systemd.services.power-monitor = {
    description = "Simple Power Monitor API";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${powerScript}/bin/power-monitor";
      Restart = "always";
      # It needs to read /sys files, so we can't restrict it too much
      User = "root"; 
    };
  };
}