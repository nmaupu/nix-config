#!/usr/bin/env bash
# Copy /var/lib/docker (images, layers, volumes, containers) from the Guix
# laptop to the mounted NixOS docker LV. Same storage driver on both sides
# (overlay2), so the tree is taken verbatim.
#
# Usage: sudo ./sync-docker.sh [--go] /mnt/var/lib/docker
#        (dry run unless --go is given)
#
# dockerd must be stopped first:  sudo herd stop dockerd
#
# -H hard links, -A acls, -X xattrs (overlay2 opaque dirs are trusted.overlay.*
# xattrs, need root), -S sparse files, --numeric-ids: container files carry
# arbitrary uids/gids that must not be remapped. Whiteouts are char devices,
# copied by -a (--devices --specials).
set -euo pipefail

src=/var/lib/docker
dry=(--dry-run)
if [ "${1:-}" = "--go" ]; then dry=(); shift; fi
dest=${1:?usage: $0 [--go] /mnt/var/lib/docker}

[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }
if pgrep -x dockerd >/dev/null; then
  echo "dockerd is running; stop it first: sudo herd stop dockerd"
  exit 1
fi
mountpoint -q "$dest" || { echo "$dest is not a mountpoint (docker LV not mounted?)"; exit 1; }

rsync -aHAXS --numeric-ids --info=progress2 --delete \
  "${dry[@]}" \
  "$src/" "$dest/"

[ ${#dry[@]} -eq 0 ] || echo "(dry run; re-run with --go to copy)"
