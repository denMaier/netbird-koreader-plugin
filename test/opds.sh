#!/bin/sh
# A reverse proxy that only answers to the site's real name, like one in front of OPDS.
apk add -q --no-cache nginx openssl
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=opds.internal \
    -keyout /tmp/k.pem -out /tmp/c.pem 2>/dev/null
cat > /etc/nginx/http.d/default.conf <<'CONF'
ssl_certificate /tmp/c.pem;
ssl_certificate_key /tmp/k.pem;
server { listen 80 default_server; listen 443 ssl default_server; return 421; }
server { listen 80; listen 443 ssl; server_name opds.internal; location / { return 200 "hello from opds"; } }
CONF
exec nginx -g 'daemon off;'
