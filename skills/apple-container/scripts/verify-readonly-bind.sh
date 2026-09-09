#!/bin/sh
set -eu

readonly EX_USAGE=64
readonly FIXTURE_CONTENT='apple-container-readonly-bind'

fixture_directory=
fixture_path=

usage() {
  printf 'usage: %s LOCAL_IMAGE_TAG\n' "$0" >&2
  exit "$EX_USAGE"
}

fail() {
  printf 'verify-readonly-bind: %s\n' "$1" >&2
  exit 1
}

calculate_sha256() {
  checksum_output=$(shasum -a 256 "$1") || fail "cannot calculate SHA-256 for '$1'"
  checksum=${checksum_output%% *}
  [ -n "$checksum" ] || fail "empty SHA-256 result for '$1'"
  printf '%s\n' "$checksum"
}

cleanup_fixture() {
  cleanup_succeeded=true
  if [ -n "${fixture_path:-}" ] && [ -e "$fixture_path" ]; then
    rm "$fixture_path" 2>/dev/null || cleanup_succeeded=false
  fi
  if [ -n "${fixture_directory:-}" ] && [ -d "$fixture_directory" ]; then
    rmdir "$fixture_directory" 2>/dev/null || cleanup_succeeded=false
  fi
  [ "$cleanup_succeeded" = true ]
}

cleanup_after_exit() {
  if ! cleanup_fixture; then
    printf 'verify-readonly-bind: cleanup left fixture path: %s\n' \
      "${fixture_directory:-unknown}" >&2
  fi
}

assert_regular_file_bind_rejected() {
  regular_file_bind_output=
  if regular_file_bind_output=$(container run --rm --progress none \
    --network none --no-dns \
    --mount "type=bind,source=$fixture_path,target=/input.txt,readonly" \
    "$image_tag" sh -c ':' 2>&1); then
    fail 'regular-file bind source unexpectedly succeeded'
  fi

  case "$regular_file_bind_output" in
    *"is not a directory"*) ;;
    *) fail "regular-file bind failed for an unexpected reason: $regular_file_bind_output" ;;
  esac
  printf 'PASS: regular-file bind source was rejected\n'
}

assert_readonly_directory_bind_enforced() {
  readonly_bind_output=
  # This script expands inside the guest, not in the host shell.
  # shellcheck disable=SC2016
  if ! readonly_bind_output=$(container run --rm --progress none \
    --network none --no-dns \
    --user 10001:10001 --cap-drop ALL \
    --mount "type=bind,source=$fixture_directory,target=/input,readonly" \
    "$image_tag" sh -eu -c '
      expected_content=$1
      actual_content=$(cat /input/input.txt)
      [ "$actual_content" = "$expected_content" ] || {
        printf "FAIL: staged input content did not match\n" >&2
        exit 1
      }
      if (printf "modified\n" >> /input/input.txt) 2>/dev/null; then
        printf "FAIL: guest write unexpectedly succeeded\n" >&2
        exit 1
      fi
      printf "PASS: non-root guest read input and write was blocked\n"
    ' sh "$FIXTURE_CONTENT" 2>&1); then
    fail "read-only directory bind verification failed: $readonly_bind_output"
  fi
  printf '%s\n' "$readonly_bind_output"
}

[ "$#" -eq 1 ] || usage
image_tag=$1

command -v container >/dev/null 2>&1 || fail 'container CLI not found'
command -v shasum >/dev/null 2>&1 || fail 'shasum not found'

if ! container image inspect "$image_tag" >/dev/null; then
  fail "cannot inspect local image '$image_tag'; check system status and local image inventory"
fi

trap cleanup_after_exit 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fixture_directory=$(mktemp -d)
fixture_path="$fixture_directory/input.txt"
chmod 700 "$fixture_directory"
printf '%s\n' "$FIXTURE_CONTENT" > "$fixture_path"
chmod 600 "$fixture_path"
digest_before=$(calculate_sha256 "$fixture_path")

assert_regular_file_bind_rejected
assert_readonly_directory_bind_enforced

digest_after=$(calculate_sha256 "$fixture_path")
[ "$digest_before" = "$digest_after" ] || fail 'host input digest changed'
printf 'PASS: host input digest is unchanged\n'

cleanup_fixture || fail "cannot remove fixture directory '$fixture_directory'"
trap - 0 HUP INT TERM
printf 'PASS: temporary fixture was removed\n'
