#!/usr/bin/env bash
# Copy /home/nmaupu from the Guix laptop to the mounted NixOS home LV, minus
# Guix-specific files (see home-rsync-exclude.txt).
#
# Usage: sudo ./sync-home.sh [--go] /mnt/home/nmaupu
#        (dry run unless --go is given)
#
# Ownership is rewritten to uid 1000 / gid 100: Guix' "users" group is 997,
# NixOS' is 100.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
src=/home/nmaupu
dry=(--dry-run)
if [ "${1:-}" = "--go" ]; then dry=(); shift; fi
dest=${1:?usage: $0 [--go] /mnt/home/nmaupu}

excl=$(mktemp)
trap 'rm -f "$excl"' EXIT
grep -vE '^\s*(#|$)' "$here/home-rsync-exclude.txt" > "$excl"
# Every symlink into the Guix store / guix profiles (home-manager owns those targets)
find "$src" -maxdepth 5 -type l \( -lname '/gnu/store*' -o -lname '*guix*' \) \
  -printf '/%P\n' >> "$excl"

echo "Excluding:"; sed 's/^/  /' "$excl"; echo

rsync -aHAX --info=progress2 --delete-excluded \
  --chown=1000:100 \
  --exclude-from="$excl" \
  "${dry[@]}" \
  "$src/" "$dest/"

[ ${#dry[@]} -eq 0 ] || echo "(dry run; re-run with --go to copy)"
