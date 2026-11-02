#!/bin/sh
# One simulated e-reader: real netbird.sh and main.lua, stubbed KOReader widgets.
set -eu
MODE=$1
apk add -q --no-cache luajit lua5.1-socket lua5.1-sec lua5.1-cjson curl dosfstools >/dev/null
export LUA_PATH="/test/?.lua;/plugin/?.lua;;"
DATA=/koreader
mkdir -p "$DATA"
if [ "$MODE" = tun ]; then
    # A FAT data dir is what really differs from a server: no chmod, no sockets.
    truncate -s 200M /tmp/fat.img
    mkfs.vfat /tmp/fat.img
    mount -o loop /tmp/fat.img "$DATA"
    mount | grep "$DATA"
    # /etc as a Kindle has it: read-only, resolv.conf a symlink into /var/run.
    cp /etc/resolv.conf /var/run/resolv.conf
    umount /etc/resolv.conf
    rm -f /etc/resolv.conf
    ln -s /var/run/resolv.conf /etc/resolv.conf
    mount --bind /etc /etc
    mount -o remount,ro,bind /etc
else
    [ ! -e /dev/net/tun ] || { rm -f /dev/net/tun; }
fi
until [ -e /shared/resource.ready ]; do sleep 1; done

# A tampered download must never end up on the device.
sed 's/^SHA256_\(arm64\|armv6\)=.*/SHA256_\1="0000"/' /plugin/netbird.sh > /tmp/tampered.sh
result=$(NB_HOME=/tmp/tampered NB_RUN=/tmp/tampered-run sh /tmp/tampered.sh install || true)
if [ "$result" = "Checksum mismatch, refusing to install" ] && [ ! -e /tmp/tampered/netbird ] && [ ! -e /tmp/tampered/netbird.tar.gz ]; then
    echo "PASS  tampered download is refused and removed"
else
    echo "FAIL  tampered download: $result"; exit 1
fi

# Kindle firmware runs X, so KOReader inherits this.
export DISPLAY=:0
exec luajit /test/harness.lua "$MODE" "$DATA" "$(cat /shared/setup.key)" "$(cat /shared/peer.ip)"
