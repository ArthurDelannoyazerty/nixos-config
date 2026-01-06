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

## Authelia
Require : LLDPA


It require secrets (to be readed in files).

```bash
sudo mkdir -p /var/lib/authelia/secrets

# Generate random secrets directly into the files
tr -cd 'a-z0-9A-Z' < /dev/urandom | head -c 64 | sudo tee /var/lib/authelia/secrets/jwt_secret > /dev/null
tr -cd 'a-z0-9A-Z' < /dev/urandom | head -c 64 | sudo tee /var/lib/authelia/secrets/session_secret > /dev/null
tr -cd 'a-z0-9A-Z' < /dev/urandom | head -c 64 | sudo tee /var/lib/authelia/secrets/storage_key > /dev/null

# Generate the hash password by executing:
# nix run nixpkgs#authelia -- crypto hash generate argon2
# copy the hashed password for the next step

# Create the user db
sudo vim /var/lib/authelia/users_database.yml

# An copy the following into that file (and modify the values, especially the password that must bethe previous hashed password):
#
# users:
#   arthur:
#     displayname: Arthur
#     # Paste the hash you generated interactively here:
#     password: "$argon2id$v=19$m=65536,t=3,p=4$DnF1c+/aA+yS+n7YSeS1bg$wD0I/..."
#     email: arthur@example.com
#     groups:
#       - admins


sudo chmod 600 /var/lib/authelia/secrets/*
sudo chown -R authelia-main:authelia-main /var/lib/authelia/secrets
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

Then when al is ready we can point the tunnels to the right endpoint
```bash
cloudflared tunnel route dns homelab-tunnel authentik.arthur-lab.com
cloudflared tunnel route dns homelab-tunnel headscale.arthur-lab.com
```