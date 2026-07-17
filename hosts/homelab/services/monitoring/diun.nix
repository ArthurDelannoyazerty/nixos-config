{ config, pkgs, myConstants, ... }:

let
  envFile = "${myConstants.paths.servicesSSD}/diun/secrets.env";
  
  # Updated Proxy: Prevents duplicates, adds HTML formatting, fixes empty URLs
  diunRssProxy = pkgs.writeText "diun-rss-proxy.py" ''
    import http.server
    import json
    import datetime
    import os
    import time

    FEED_FILE = "/var/lib/services/diun/feed.json"
    MAX_ITEMS = 50

    def load_feed():
        if os.path.exists(FEED_FILE):
            try:
                with open(FEED_FILE, "r") as f:
                    return json.load(f)
            except Exception:
                pass
        return {
            "version": "https://jsonfeed.org/version/1.1",
            "title": "Diun Docker Updates",
            "home_page_url": "https://github.com/crazy-max/diun",
            "feed_url": "http://host.docker.internal:8011/feed.json",
            "items": []
        }

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

                feed = load_feed()
                
                image = data.get("image", "Unknown")
                status = data.get("status", "new")
                hub_link = data.get("hub_link", "")
                
                # If Diun's test payload sends an empty link, generate a fallback
                if not hub_link:
                    image_name = image.split(":")[0] if ":" in image else image
                    hub_link = f"https://hub.docker.com/search?q={image_name}"
                    
                now_utc = datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z")
                created = data.get("created", now_utc)
                
                # Adding the current timestamp to the ID ensures FreshRSS NEVER sees a duplicate ID, 
                # even if you run the test command 10 times in a row!
                unique_id = f"{image}_{created}_{int(time.time())}"
                
                item = {
                    "id": unique_id,
                    "title": f"Update: {image}",
                    "content_text": f"Status: {status}\nImage: {image}\nLink: {hub_link}",
                    "content_html": f"<ul><li><b>Status:</b> {status}</li><li><b>Image:</b> <code>{image}</code></li><li><b>Link:</b> <a href='{hub_link}'>View on Docker Hub</a></li></ul>",
                    "url": hub_link,
                    "date_published": created
                }
                
                feed["items"].insert(0, item)
                feed["items"] = feed["items"][:MAX_ITEMS]
                
                save_feed(feed)
                
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"OK")
            else:
                self.send_response(404)
                self.end_headers()
                
        def do_GET(self):
            if self.path == "/feed.json":
                feed = load_feed()
                self.send_response(200)
                # FreshRSS prefers application/json or application/feed+json. Let's use the standard.
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
  virtualisation.oci-containers.containers.${myConstants.services.diun.containerName} = {
    image = "ghcr.io/crazy-max/diun:${myConstants.services.diun.version}";
    volumes = [ "/var/run/docker.sock:/var/run/docker.sock:ro" ];
    environmentFiles = [ envFile ]; 
    environment = {
      TZ = "Europe/Paris";
      LOG_LEVEL = "info";
      DIUN_WATCH_SCHEDULE = "0 2 * * *"; 
      DIUN_PROVIDERS_DOCKER = "true";
      DIUN_PROVIDERS_DOCKER_WATCHBYDEFAULT = "true";
      DIUN_NOTIF_WEBHOOK_ENDPOINT = "http://${myConstants.dockerSocketProxy}:8011/webhook";
      DIUN_NOTIF_WEBHOOK_METHOD = "POST";
      DIUN_NOTIF_WEBHOOK_HEADERS_CONTENT_TYPE = "application/json";
    };
  };

  systemd.services.diun-rss-proxy = {
    description = "Proxy that converts Diun webhooks into a JSON Feed for FreshRSS";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python ${diunRssProxy}";
      Restart = "always";
      User = "root"; 
    };
  };

  systemd.tmpfiles.rules = [
    "d ${myConstants.paths.servicesSSD}/diun 0700 root root -"
  ];

  # CRITICAL: Allow Docker containers (like FreshRSS) to reach the host on port 8011
  networking.firewall.interfaces."docker0".allowedTCPPorts = [ 8011 ];
  # Fallback in case your docker network uses a different interface name (br-xxx)
  networking.firewall.allowedTCPPorts = [ 8011 ];
}