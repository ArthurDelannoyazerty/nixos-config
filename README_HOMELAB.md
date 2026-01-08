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

## Authetik
Require : LLDPA

```bash
sudo mkdir -p /var/lib/authentik

# Create a fresh file or overwrite the broken one
# Generate a new random password and key
PW=$(openssl rand -base64 24)
KEY=$(openssl rand -base64 36)

# Write them to the file using both variable names
sudo bash -c "cat <<EOF > /var/lib/authentik/secrets.env
AUTHENTIK_SECRET_KEY=$KEY
AUTHENTIK_POSTGRESQL__PASSWORD=$PW
POSTGRES_PASSWORD=$PW
EOF"

# Secure the file
sudo chmod 600 /var/lib/authentik/secrets.env
```


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
```