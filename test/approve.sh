#!/bin/sh
# Do what a phone does with the QR code: open the URL, sign in, approve the device.
# Usage: approve.sh <device url> <email> <password>
# Uses --data, not -X POST: like a browser, curl must turn to GET on redirects.
set -u
URL=$1 EMAIL=$2 PASS=$3
JAR=/tmp/approve.jar
rm -f "$JAR"
base=${URL%%/oauth2/*}
code=$(printf %s "$URL" | sed -n 's/.*user_code=\([^&]*\).*/\1/p')
curl -fsSL -c "$JAR" -b "$JAR" -o /dev/null "$URL" || exit 1
# Confirming the code leads to the login page.
login=$(curl -fsSL -c "$JAR" -b "$JAR" -o /dev/null -w '%{url_effective}' \
    --data-urlencode "user_code=$code" "$base/oauth2/device/auth/verify_code") || exit 1
page=$(curl -fsSL -c "$JAR" -b "$JAR" -o /tmp/after.html -w '%{url_effective}' \
    --data-urlencode "login=$EMAIL" --data-urlencode "password=$PASS" "$login") || exit 1
# Grant access, if the provider asks.
req=$(sed -n 's/.*name="req" value="\([^"]*\)".*/\1/p' /tmp/after.html | head -n1)
if [ -n "$req" ]; then
    curl -fsSL -c "$JAR" -b "$JAR" -o /tmp/after.html \
        --data-urlencode "req=$req" --data-urlencode "approval=approve" "$page" || exit 1
fi
