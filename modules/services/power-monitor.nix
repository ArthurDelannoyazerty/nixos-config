{ config, pkgs, myConstants, ... }:

let
  port = myConstants.services.power-monitor.port;
  kwhPrice = 0.22; # Price in €/kWh
  idleOffset = 15; # Watt offset for non-CPU components (Motherboard, RAM, Fans)

  powerScript = pkgs.writeScriptBin "power-monitor" ''
    #!${pkgs.python3}/bin/python3
    import http.server
    import socketserver
    import time
    import json
    import os

    # Path to Intel RAPL sensor
    RAPL_PATH = "/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj"
    
    def read_energy():
        try:
            with open(RAPL_PATH, "r") as f:
                return int(f.read())
        except:
            return 0

    def get_instant_watts():
        try:
            t1 = time.time()
            e1 = read_energy()
            time.sleep(0.25) # Wait 250ms to measure consumption
            t2 = time.time()
            e2 = read_energy()
            
            # 1. Prevent division by zero
            # 2. Handle sensor wrapping/reset
            if e2 < e1 or (t2 - t1) == 0: 
                return 0
                
            joules_delta = (e2 - e1) / 1_000_000
            time_delta = t2 - t1
            return joules_delta / time_delta
        except:
            return 0

    class Handler(http.server.SimpleHTTPRequestHandler):
        def do_GET(self):
            cpu_watts = get_instant_watts()
            
            # If RAPL fails (returns 0), we still show the idle offset
            total_watts = cpu_watts + ${toString idleOffset}
            
            # Monthly Cost Calculation
            monthly_cost = (total_watts / 1000) * ${toString kwhPrice} * 24 * 30

            # Return a FLAT JSON object so Homepage can find the keys
            data = {
                "Usage": f"{total_watts:.1f} W",
                "Cost": f"{monthly_cost:.2f}€"
            }

            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())

    # Allow the port to be reused immediately if service restarts
    socketserver.TCPServer.allow_reuse_address = True
    
    with socketserver.TCPServer(("127.0.0.1", ${toString port}), Handler) as httpd:
        print(f"Serving power stats on port ${toString port}")
        httpd.serve_forever()
  '';
in
{
  boot.kernelModules = [ "msr" "powercap" "intel_rapl_common" ];

  systemd.services.power-monitor = {
    description = "Simple Power Monitor API";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${powerScript}/bin/power-monitor";
      Restart = "always";
      User = "root"; 
    };
  };
}