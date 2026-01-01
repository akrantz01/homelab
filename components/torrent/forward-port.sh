#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

if [[ -n "${DEBUG:-}" ]]; then
  set -o xtrace
fi

GATEWAY="${GATEWAY:-10.2.0.1}"
QBITTORRENT_API_PORT="${QBITTORRENT_API_PORT:-8080}"

udp_port="$(natpmpc -g "$GATEWAY" -a 1 0 udp | awk '/Mapped public port/ { print $4 }')"
tcp_port="$(natpmpc -g "$GATEWAY" -a 1 0 udp | awk '/Mapped public port/ { print $4 }')"
if [[ "$udp_port" != "$tcp_port" ]]; then
  echo "Mismatch ports!"
  echo "  UDP: $udp_port"
  echo "  TCP: $tcp_port"
  exit 1
fi

echo "Acquired port: $udp_port"

curl --silent --fail --request POST \
    --data-urlencode "json={\"listen_port\": ${udp_port}}" \
    "http://127.0.0.1:${QBITTORRENT_API_PORT}/api/v2/app/setPreferences"

echo "Sucessfully updated qBittorrent listen port"
