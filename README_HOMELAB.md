# Services First Time Setup

## Vikunja

It need a JWT token so you do :
```bash
sudo mkdir -p /var/lib/vikunja

# Generate a random secret and save it to a .env file
echo "VIKUNJA_SERVICE_JWTSECRET=$(openssl rand -base64 32)" | sudo tee /var/lib/vikunja/secret.env
```
Now you need to write the folllowing in the vikunja secret : 

```vim
# Enable OIDC
VIKUNJA_AUTH_OPENID_ENABLED=true

# Provider Settings (The 'authentik' part in the key is your provider ID)
VIKUNJA_AUTH_OPENID_PROVIDERS_authentik_NAME=Authentik
VIKUNJA_AUTH_OPENID_PROVIDERS_authentik_AUTHURL=https://authentik.yourdomain.com/application/o/vikunja/
VIKUNJA_AUTH_OPENID_PROVIDERS_authentik_CLIENTID=your_client_id_from_authentik
VIKUNJA_AUTH_OPENID_PROVIDERS_authentik_CLIENTSECRET=your_client_secret_from_authentik

# Scopes required
VIKUNJA_AUTH_OPENID_PROVIDERS_authentik_SCOPE=openid profile email
```

For the Authentik OIDC, you also need to create the Authentik Application and Provider (OAUT2/OIDC) (implicit consent) (confidential) (https://vikunja.yourdomain.com/auth/openid/authentik). 
Then, cloudflare now blocks the Vikunja requests to Authentik (because vikunja exit our server and go back inside by Cloudflare). We thus need to create a bypass :
1. Got to cloudflare Zero Trust Dashboard
2. Policies -> Create new Policy
3. Policy Name = Internal Server Bypass  |  Action = Bypass  |  Include = IP Range 
4. Fill that field with your local IP using `curl -6 ifconfig.me` and `curl -4 ifconfig.me` (Use CIDR notation : IPV6/128 | IPV4/32)
5. Now Save, Select the *.yourdomain.com and set that policy at the top
6. Now, requests from the set IP (ourself) can pass through cloudflare ! 



## LLDAP

Used as a backend for Authelia

1. Pre-build setup
```bash    
sudo mkdir -p /var/lib/lldap/secrets
tr -cd 'a-z0-9A-Z' < /dev/urandom | head -c 32 | sudo tee /var/lib/lldap/secrets/admin_password
tr -cd 'a-z0-9A-Z' < /dev/urandom | head -c 64 | sudo tee /var/lib/lldap/secrets/jwt_secret
```

2. Post-build setup
```bash
# Change recursively the owner of these fodlder to the lldapp user can use them
sudo chown -R lldap:lldap /var/lib/lldap/

sudo chmod 700 /var/lib/lldap/secrets 
sudo chmod 600 /var/lib/lldap/secrets/admin_password
sudo chmod 600 /var/lib/lldap/secrets/jwt_secret

# If needed
sudo systemctl restart lldap
```

## Authentik
Require : LLDPA

1. Pre-build setup
```bash
sudo mkdir -p /var/lib/authentik

# Create a fresh file or overwrite the broken one
# Generate a new random password and key
PW=$(openssl rand -base64 24)
KEY=$(openssl rand -base64 36)

# Write them to the file using both variable names
# AUTHENTIK_SECRET_KEY: Used to encrypt browser cookies and tokens
# AUTHENTIK_POSTGRESQL__PASSWORD: The password the server uses to talk to the database.
# POSTGRES_PASSWORD: The password the database sets for itself on startup. 
sudo bash -c "cat <<EOF > /var/lib/authentik/secrets.env
AUTHENTIK_SECRET_KEY=$KEY
AUTHENTIK_POSTGRESQL__PASSWORD=$PW
POSTGRES_PASSWORD=$PW
EOF"

# Secure the file initially
sudo chmod 600 /var/lib/authentik/secrets.env
```

2. Post-build setup
```bash
# Permission changes (The 'authentik' user exists only after rebuild)
sudo chown authentik:authentik /var/lib/authentik/secrets.env
sudo chown -R 1000:1000 /var/lib/authentik/media
sudo chown -R 1000:1000 /var/lib/authentik/certs
sudo chown -R 1000:1000 /var/lib/authentik/custom-templates

# NOW restart services so it reads the password file
sudo systemctl restart docker-authentik-server
sudo systemctl restart docker-authentik-worker
```

1. Troubleshooting
```bash
# Test Authentik if error 502
curl -I http://127.0.0.1:9000/
# Examine logs
docker logs authentik-server --tail 50
# restart services
systemctl restart docker-authentik-server
systemctl restart docker-authentik-worker

# Then put the bootstrap admin password manually with:
# sudo vim /var/lib/authentik/secrets.env
# AUTHENTIK_BOOTSTRAP_PASSWORD=YourStrongPasswordHere
# AUTHENTIK_BOOTSTRAP_EMAIL=YourEmail
```

Then, after cloudflare work and you have access to the website, you will need to 
1. Log in as admin (login: akadmin | password: the one set as AUTHENTIK_BOOTSTRAP_PASSWORD). 
2. Go to `Settings` and `Change password`
3. Remove the `BOOTSTRAP` env variables in `/var/lib/authentik/secrets.env`


For the step `1. login`, if you have "Invalid password":
1. Find the `.py` script : `sudo docker exec -it authentik-server find / -name manage.py 2>/dev/null`
2. Execute is to get a token to lon in as root : `sudo docker exec -it authentik-server python3 /manage.py create_recovery_key 1 akadmin`
3. You will receive something like `/recovery/use-token/<TOKEN>/`. Use it to go to : `https://authentik.<YOUR-DOMAIN>/recovery/use-token/<TOKEN>/`
4. You are now logged as akadmin, go to the previous point `2`

For using the option `Connect with Google account` :
1. Go to https://console.cloud.google.com
2. Search `New project`. Name it `Homelab-SSO`
3. Now search `OAuth Consent Screen`
4. Target = External | email = Your email
5. Go to the left menu : `Credential` -> `Create a credential`
6. Application Type = Web app | name = Authentik Server | Authorized redirect URIs = `https://authentik.<YOUR-DOMAIN>/source/oauth/callback/google/`
7. Create. Copy the `Client ID` and the `Cllient Secret` and copy them into authentik app (Authentik -> Directory (left menu) -> Federation & Social Login -> Create Google OAuth Source)

Set up Authentik login page
1. Got to Step -> Search `default-authentication-identification` and edit it
2. Password step = default-authentication-password --> Let users sign up
3. Source available = google (the one your just created before)

Now we want other apps to use Authentik when a user arrive in them.
1. Go to Authentik as `akadmin`
2. Application -> Provider -> Create Provider -> Proxy provider
3. Name = Homepage-provider (example service) |  Authorization flux = default-provider-authorization-implicit-consent | External host = https://homepage.<YOUR-DOMAIN> | Internal host = http://127.0.0.1:3000 (the internal service ip:port)
4. Application -> Application -> Create applicaiton 
5. Name = Homepage | slug = homepage | Provider = Homepage-provider | UI Setting -> Launch URL = https://homepage.<YOUR-DOMAIN>
6. Now go in the newly created application -> Policy -> Create binding -> add group -> Select the group that have access to that website (when someone go into your homepage service, they will ask to authentik about its group identity, if not included into they will not be authorized)

Now we want authentik to actually accept redirect from the other websites
1. Applications -> Outposts
2. Modify the default "authentik Embedded Outpost" : Add the applications you want
3. Save

For Vikunja :
1. Got to Outpost
2. Follow : https://integrations.goauthentik.io/chat-communication-collaboration/vikunja/
3. Don't forget to set up the Client ID and client secret in the Vikunja section above

## Cloudflared

```bash
(nix shell nixpkgs#cloudflared)
cloudflared tunnel login
cloudflared tunnel create homelab-tunnel
# This created a tunnel secret and printed a UUID (use it in the following commands)

sudo mkdir -p /var/lib/cloudflared
sudo cp ~/.cloudflared/<YOUR-UUID>.json /var/lib/cloudflared/cert.json
sudo chmod 600 /var/lib/cloudflared/cert.json

# After the rebuild, when cloudflared wil turn on :
sudo chown cloudflared:cloudflared /var/lib/cloudflared/cert.json
```

Then update the UUID in the `cloudflared.nix` file.

Then we need to set up the Cloudflare CNAME (that link the DNS address to the tunnel we created)

1. Go to the Cloudflare dashboard -> DNS -> Records
2. Create a Record for the root domain : Type=CNAME | name=<YOUR-DOMAIN-ROOT> | target=<TUNNEL-UUID>.cfargotunnel.com | Proxied=true
3. Create a Record for all the subdomain : Type=CNAME | name=* (actually idk if it is only '*' or '*'.<YOUR-DOMAIN-ROOT>) | target=<TUNNEL-UUID>.cfargotunnel.com | Proxied=true

Before opening the server to all the internet, we need to verify that it work well. However for that we still need a working DNS record. So we create one but that only us can use with a one time PIN

1. Go to cloudflare zero trust dashboard
2. 'Access control' -> 'Application' -> 'Add an application' -> 'Self Hosted'
3. Application name="Homelab"
4. Public Hostname=*.<YOUR-DNS-DOMAIN>
5. Accept all available identity providers = false
6. Check 'One-time PIN'
7. Create a policy. Action = "Allow" | Include : "Emails" = YOUR-MAIL
8. Create that app. After that only your email can receive a one time pin code to access your server (it is secured!)
9. Do the same for the root domain : Application name="Homelab" | Public Hostname=<YOUR-DNS-DOMAIN>

## Forgejo

Nothing particular to configure, it may just fail when rebuild nixos sometimes but is actually running (rebuild if needed, it shuold work)

To Mirror your Github account : 

Create the small script :
```bash
vim ~/forgejo_github_migration.sh
```

Copy the script (and modify the parameters) :
```bash
#!/usr/bin/env bash

# --- CONFIGURATION ---
GITHUB_USER="YOUR-GITHUB-USER"
# Your GitHub Personal Access Token (Needs 'repo' scope)
GITHUB_TOKEN="ghp_your_github_token_here"

FORGEJO_URL="http://127.0.0.1:FORGEJO-PORT"     # use local port to ease the process (no auth error)
FORGEJO_TOKEN="your_forgejo_token_here"
# ---------------------

echo "Fetching repositories from GitHub..."

# Ask GitHub for all your repositories (up to 100)
REPOS_JSON=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/user/repos?type=owner&per_page=100")

# Extract names using jq
REPOS=$(echo $REPOS_JSON | jq -r '.[].name')

count=0

for REPO in $REPOS; do
  echo -n "Processing $REPO... "

  # Check if private on GitHub (to set private on Forgejo)
  IS_PRIVATE=$(echo $REPOS_JSON | jq -r ".[] | select(.name==\"$REPO\") | .private")

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}\n" -X POST "$FORGEJO_URL/api/v1/repos/migrate" \
    -H "accept: application/json" \
    -H "Authorization: token $FORGEJO_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"auth_token\": \"$GITHUB_TOKEN\",
      \"clone_addr\": \"https://github.com/$GITHUB_USER/$REPO.git\",
      \"mirror\": true,
      \"repo_name\": \"$REPO\",
      \"service\": \"github\",
      \"private\": $IS_PRIVATE,
      \"wiki\": true,
      \"labels\": true,
      \"issues\": true,
      \"pull_requests\": true,
      \"releases\": true
    }")

  if [ "$HTTP_CODE" == "201" ]; then
    echo "✅ MIGRATED"
  elif [ "$HTTP_CODE" == "409" ]; then
    echo "⏭️  SKIPPED (Already exists)"
  else
    echo "❌ ERROR (Status: $HTTP_CODE)"
  fi
    
  # Sleep to not overload the server
  sleep 2
done

echo "Migration commands sent! Check your Forgejo dashboard."
```

Now run the script : 
```bash
chmod +x ~/forgejo_github_migration.sh
nix-shell -p curl jq --run ~/forgejo_github_migration.sh
```


# To add other services

1. Add an entry in `modules/constants.nix`:
    ```nix
    services = {
        YOUR-SERVICE = {
            port = 3456;
            subdomain = "YOUR-SERVICE";
            version = "1.1.0"; # If using docker
        };
    }
    ```
2. Create your service file in `modules/services/YOUR-SERVICE.nix`
    - Module input = `{ config, pkgs, myConstants, ... }: `
    - Use your constants: `port = MyConstants.services.YOUR-SERVICE.port;` (for example)
3. Add that file in `hosts/HOST/configuration.nix` 
     ```nix
    imports = [
        ../../modules/services/scrutiny.nix
    ];
    ```
3. Add to `modules/services/caddy.nix` the following :
    - ```nix
        services.caddy = {
            virtualHosts = {
                # --- YOUR-SERVICE ---
                "http://${myConstants.services.YOUR-SERVICE.subdomain}.${domain}" = {
                    extraConfig = ''
                    log
                    ${authentikMiddleware} # Inject the auth logic
                    reverse_proxy 127.0.0.1:${toString myConstants.services.YOUR-SERVICE.port}
                    '';
              };
           };
        };
    ```
4. In Authentik
    1. create a provider 
        - Proxy or OAUTH/OIDC depending on the service
        - implicit consent
        - Transfer authentification (unique app)
        - https://YOUR-SERVICE.YOUR-DOMAIN.com 
    2. An application 
        - name=YOUR-SERVICE
    3. Add that to the Embedded Authentik Outpost
5. Optional : Add the link in the homepage to access it easily
6. Optional : Add that service to Uptime Kuma