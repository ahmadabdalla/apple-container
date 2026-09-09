#!/bin/sh
set -eu

readonly EX_USAGE=64

usage() {
  printf 'usage: %s LOCAL_IMAGE_TAG\n' "$0" >&2
  exit "$EX_USAGE"
}

fail() {
  printf 'verify-offline: %s\n' "$1" >&2
  exit 1
}

[ "$#" -eq 1 ] || usage
image_tag=$1
script_dir=$(CDPATH='' cd "$(dirname "$0")" && pwd)
guest_probe_path="$script_dir/verify-offline-guest.sh"

[ -r "$guest_probe_path" ] || fail "guest probe is not readable: $guest_probe_path"
command -v container >/dev/null 2>&1 || fail "container CLI not found"

if ! container image inspect "$image_tag" >/dev/null; then
  fail "cannot inspect local image '$image_tag'; check system status and local image inventory"
fi

exec container run --rm --interactive --network none --no-dns \
  "$image_tag" sh -eu -s < "$guest_probe_path"
