#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

if [[ -n "${DEBUG:-}" ]]; then
  set -o xtrace
fi

GATEWAY="${GATEWAY:-10.2.0.1}"
DELUGE_USER="${DELUGE_USER:-localclient}"
DELUGE_DATA_DIR="${DELUGE_DATA_DIR:-/var/lib/deluge}"

if [[ -z "${DELUGE_PASSWORD:-}" ]]; then
  DELUGE_PASSWORD="$(grep "^${DELUGE_USER}" "$DELUGE_DATA_DIR/.config/deluge/auth" | head -n 1 | awk -F':' '{ print $2 }')"
fi

udp_port="$(natpmpc -g "$GATEWAY" -a 1 0 udp | awk '/Mapped public port/ { print $4 }')"
tcp_port="$(natpmpc -g "$GATEWAY" -a 1 0 udp | awk '/Mapped public port/ { print $4 }')"
if [[ "$udp_port" != "$tcp_port" ]]; then
  echo "Mismatch ports!"
  echo "  UDP: $udp_port"
  echo "  TCP: $tcp_port"
  exit 1
fi

deluge-console \
  -U "$DELUGE_USER" \
  -P "$DELUGE_PASSWORD" \
  "config --set random_port false; config --set listen_ports (${udp_port}, ${udp_port})"
