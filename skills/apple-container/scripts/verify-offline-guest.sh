#!/bin/sh
set -eu

assert_probe_fails() {
  probe_name=$1
  shift
  if probe_output=$("$@" 2>&1); then
    printf 'FAIL: %s unexpectedly succeeded\n' "$probe_name" >&2
    if [ -n "$probe_output" ]; then
      printf 'Probe output:\n%s\n' "$probe_output" >&2
    fi
    exit 1
  fi
  printf 'PASS: %s failed as expected\n' "$probe_name"
}

for required_command in ip nslookup wget; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'FAIL: required command not found: %s\n' "$required_command" >&2
    exit 1
  fi
done

interface_names=$(ls /sys/class/net)
if [ "$interface_names" != lo ]; then
  printf 'FAIL: expected only loopback; found: %s\n' "$interface_names" >&2
  exit 1
fi
printf 'PASS: loopback is the only interface\n'

ipv4_default_route=$(ip -4 route show default)
ipv6_default_route=$(ip -6 route show default)
if [ -n "$ipv4_default_route$ipv6_default_route" ]; then
  printf 'FAIL: found an IPv4 or IPv6 default route\n' >&2
  [ -z "$ipv4_default_route" ] || printf 'IPv4: %s\n' "$ipv4_default_route" >&2
  [ -z "$ipv6_default_route" ] || printf 'IPv6: %s\n' "$ipv6_default_route" >&2
  exit 1
fi
printf 'PASS: no IPv4 or IPv6 default route\n'

assert_probe_fails "DNS lookup" nslookup example.com
assert_probe_fails "hostname access" wget -q -T 2 -O /dev/null http://example.com
assert_probe_fails "public IPv4 route" ip -4 route get 1.1.1.1
assert_probe_fails "public IPv6 route" ip -6 route get 2606:4700:4700::1111

for address in 10.0.0.1 172.16.0.1 192.168.0.1 169.254.169.254; do
  assert_probe_fails "$address route" ip -4 route get "$address"
done

printf 'PASS: offline containment verified\n'
