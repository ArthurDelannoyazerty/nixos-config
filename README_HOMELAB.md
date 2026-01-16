# Services First Time Setup

## Vikunja

It need a JWT token so you do :
```bash
sudo mkdir -p /var/lib/vikunja

# Generate a random secret and save it to a .env file
echo "VIKUNJA_SERVICE_JWTSECRET=$(openssl rand -base64 32)" | sudo tee /var/lib/vikunja/secret.env

# Lock down permissions so only root can read it
sudo chmod 600 /var/lib/vikunja/secret.env
```


## LLDAP

Used as a backend for Authelia

```bash    
sudo mkdir -p /var/lib/lldap/secrets
tr -cd 'a-z0-9A-Z' < /dev/urandom | head -c 32 | sudo tee /var/lib/lldap/secrets/admin_password
tr -cd 'a-z0-9A-Z' < /dev/urandom | head -c 64 | sudo tee /var/lib/lldap/secrets/jwt_secret

sudo chmod 700 /var/lib/lldap/secrets
```

## Authentik
Require : LLDPA

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

# Secure the file
sudo chmod 600 /var/lib/authentik/secrets.env


# Some permission changes
sudo chown -R 1000:1000 /var/lib/authentik/media
sudo chown -R 1000:1000 /var/lib/authentik/certs
sudo chown -R 1000:1000 /var/lib/authentik/custom-templates

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
2. Password step = default-authentication-password --> LEt users sign up
3. Source available = google (the one your just created before)

Now we want other apps to use Authentik when a user arrive in them.
1. Go to Authentik as `akadmin`
2. Application -> Provider -> Create Provider -> Proxy provider
3. Name = Homepage-provider (example service) |  Authorization flux = default-provider-authorization-implicit-consent | External host = https://homepage.<YOUR-DOMAIN> | Internal host = http://127.0.0.1:3000 (the internal service ip:port)
4. Application -> Application -> Create applicaiton 
5. Name = Homapage | slug = homepage | Provider = Homepage-provider | UI Setting -> Launch URL = https://homepage.<YOUR-DOMAIN>
6. Now go in the newly created application -> Policy -> Create binding -> add group -> Select the group that have access to that website (when someone go into your homepage service, they will ask to authentik about its group identity, if not included into they will not be authorized)

## Cloudflared

```bash
nix shell nixpkgs#cloudflared
cloudflared tunnel login
cloudflared tunnel create homelab-tunnel

sudo mkdir -p /var/lib/cloudflared
sudo cp ~/.cloudflared/<YOUR-UUID>.json /var/lib/cloudflared/cert.json
sudo chmod 600 /var/lib/cloudflared/cert.json

# After the rebuild, when cloudflared wil turn on :
sudo chown cloudflared:cloudflared /var/lib/cloudflared/cert.json
```

Before opening the server to all the internet, we need to verify that it work well.However for that we still need a working DNS record. So we create one but that only us can use with a one time PIN

1. Go to cloudflare zero trust dashboard
2. 'Access control' -> 'Application' -> 'Add an application' -> 'Self Hosted'
3. Application name = "Authentik Admin"
4. Public Hostname: authentik.YOUR-DNS-DOMAIN/
5. Accept all available identity providers = false
6. Check 'One-time PIN'
7. Create a policy. Action = "Allow" | Include : "Emails" = YOUR-MAIL
8. Create that app. After that only your email can receive a one time pin code to access your server (it is secured!)


Then when all is ready we can point the tunnels to the right endpoint
```bash
cloudflared tunnel route dns homelab-tunnel authentik.arthur-lab.com
cloudflared tunnel route dns homelab-tunnel headscale.arthur-lab.com
cloudflared tunnel route dns homelab-tunnel arthur-lab.com
cloudflared tunnel route dns homelab-tunnel homelab.arthur-lab.com
```
