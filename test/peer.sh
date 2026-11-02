#!/bin/sh
# The far end: joins with the setup key and serves a known file over the tunnel.
set -eu
apk add -q --no-cache curl jq busybox-extras openssl
V=0.82.0
curl -fsSL "https://github.com/netbirdio/netbird/releases/download/v$V/netbird_${V}_linux_arm64.tar.gz" | tar xz -C /usr/local/bin netbird
until [ -s /shared/setup.key ]; do sleep 1; done
netbird service run --log-file console >/tmp/nb.log 2>&1 &
sleep 3
netbird up --management-url http://netbird-server:80 --setup-key-file /shared/setup.key --disable-dns --no-browser
mkdir -p /www && echo "hello from the peer" > /www/index.html
httpd -p 8080 -h /www
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=peer -keyout /tmp/k.pem -out /tmp/c.pem 2>/dev/null
(cd /www && openssl s_server -quiet -accept 8443 -key /tmp/k.pem -cert /tmp/c.pem -WWW) &
until netbird status --json | jq -e '.netbirdIp != ""' >/dev/null; do sleep 1; done
netbird status --json | jq -r .netbirdIp | cut -d/ -f1 > /shared/peer.ip
echo "peer up at $(cat /shared/peer.ip)"
sh /test/resource.sh
tail -f /dev/null
