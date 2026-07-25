{ config, pkgs, myConstants, ... }:

let
  # The proxy receives the Watchtower summary and translates it into a 1-item JSON RSS feed.
  watchtowerRssProxy = pkgs.writeText "watchtower-rss-proxy.py" ''
    import http.server
    import json
    import datetime
    import os

    FEED_FILE = "/var/lib/services/watchtower/feed.json"

    def save_feed(feed):
        os.makedirs(os.path.dirname(FEED_FILE), exist_ok=True)
        with open(FEED_FILE, "w") as f:
            json.dump(feed, f, indent=2)

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_POST(self):
            if self.path == "/webhook":
                length = int(self.headers.get("Content-Length", 0))
                try:
                    data = json.loads(self.rfile.read(length))
                except json.JSONDecodeError:
                    self.send_response(400)
                    self.end_headers()
                    return
                
                # Shoutrrr payload places Watchtower's output in the 'message' field
                message = data.get("message", "No updates found.")
                
                # Format into a clean HTML list for FreshRSS
                lines = [line.strip() for line in message.split('\n') if line.strip()]
                html_lines = "".join(f"<li>{line}</li>" for line in lines)
                content_html = f"<ul>{html_lines}</ul>" if html_lines else "<i>All containers are up to date!</i>"

                today_str = datetime.date.today().isoformat()
                now_iso = datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z")

                # Creating a new ID each day ensures FreshRSS pings you with a new "Unread" article daily
                item = {
                    "id": f"watchtower_summary_{today_str}",
                    "title": f"Homelab Pending Updates - {today_str}",
                    "content_text": message,
                    "content_html": content_html,
                    "date_published": now_iso
                }

                feed = {
                    "version": "https://jsonfeed.org/version/1.1",
                    "title": "Docker Update Summary",
                    "feed_url": "http://host.docker.internal:8011/feed.json",
                    # WARNING: We ONLY supply 1 item in this array so the file stays tiny
                    "items": [item] 
                }
                
                save_feed(feed)
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"OK")
                
        def do_GET(self):
            if self.path == "/feed.json":
                try:
                    with open(FEED_FILE, "r") as f:
                        feed = json.load(f)
                except Exception:
                    feed = {"version": "https://jsonfeed.org/version/1.1", "title": "Docker Update Summary", "items": []}
                
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps(feed).encode("utf-8"))
            else:
                self.send_response(404)
                self.end_headers()

    server = http.server.HTTPServer(("0.0.0.0", 8011), Handler)
    server.serve_forever()
  '';
in
{
  virtualisation.oci-containers.containers.watchtower = {
    image = "containrrr/watchtower:latest";
    volumes = [ 
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
    environment = {
      TZ = "Europe/Paris";
      # CRITICAL: Ensures Watchtower DOES NOT update your containers automatically
      WATCHTOWER_MONITOR_ONLY = "true";
      # Runs every day at 08:00:00 AM (Watchtower uses 6-field cron)
      WATCHTOWER_SCHEDULE = "0 0 8 * * *"; 
      # Enable webhooks via Shoutrrr
      WATCHTOWER_NOTIFICATIONS = "shoutrrr";
      WATCHTOWER_NOTIFICATION_URL = "generic://${myConstants.dockerSocketProxy}:8011/webhook"; 
    };
  };

  systemd.services.watchtower-rss-proxy = {
    description = "Proxy that converts Watchtower webhooks into a JSON Feed";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python ${watchtowerRssProxy}";
      Restart = "always";
      User = "root"; 
    };
  };

  systemd.tmpfiles.rules = [
    "d ${myConstants.paths.servicesSSD}/watchtower 0700 root root -"
  ];

  # Expose port 8011 so Watchtower can hit the Python proxy via the Docker gateway
  networking.firewall.interfaces."docker0".allowedTCPPorts = [ 8011 ];
  networking.firewall.allowedTCPPorts = [ 8011 ];
}

