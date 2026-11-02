#!/bin/sh
# End-to-end test against a real NetBird server. Needs Docker on an arm64 host.
cd "$(dirname "$0")" || exit 1
trap 'docker compose --profile test down -v >/dev/null 2>&1' EXIT
docker compose up -d --quiet-pull --pull always server setup peer opds || exit 1
status=0
for reader in reader-tun reader-netstack; do
    echo "=== $reader"
    docker compose run --pull always --rm -T "$reader" || status=1
done
exit $status
