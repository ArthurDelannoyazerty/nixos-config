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
