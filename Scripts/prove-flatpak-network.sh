#!/usr/bin/env bash
# Prove sandbox /proc/net/dev vs host /proc/net/dev inside Flatpak.
# Run from GNOME Builder Run panel or: flatpak run com.needletails.systeminsights bash -c "$(cat Scripts/prove-flatpak-network.sh)"
set -euo pipefail

IFACE="${1:-enp0s1}"
SPAWN=""
for candidate in /usr/bin/flatpak-spawn /usr/libexec/flatpak-spawn; do
  if [[ -x "$candidate" ]]; then
    SPAWN="$candidate"
    break
  fi
done

echo "=== System Insights Flatpak network proof ==="
echo "FLATPAK_ID=${FLATPAK_ID:-not-set}"
echo "Interface=${IFACE}"
echo

read_counter() {
  local source="$1"
  local file="$2"
  awk -v iface="$IFACE:" '$1 == iface { print $2, $10; exit }' "$file" 2>/dev/null || echo "0 0"
}

SANDBOX_FILE="/proc/net/dev"
if [[ ! -r "$SANDBOX_FILE" ]]; then
  echo "ERROR: sandbox $SANDBOX_FILE not readable"
  exit 1
fi

read -r SB_RX SB_TX < <(read_counter sandbox "$SANDBOX_FILE")
echo "1) Sandbox /proc/net/dev  rx_total=${SB_RX} tx_total=${SB_TX}"

if [[ -n "$SPAWN" ]]; then
  HOST_DEV="$($SPAWN --host cat /proc/net/dev)"
  read -r H1_RX H1_TX < <(awk -v iface="$IFACE:" '$1 == iface { print $2, $10; exit }' <<<"$HOST_DEV")
  echo "2) Host via flatpak-spawn rx_total=${H1_RX} tx_total=${H1_TX}"
  echo "   Waiting 3s while you browse/download if possible…"
  sleep 3
  HOST_DEV2="$($SPAWN --host cat /proc/net/dev)"
  read -r H2_RX H2_TX < <(awk -v iface="$IFACE:" '$1 == iface { print $2, $10; exit }' <<<"$HOST_DEV2")
  H_RX_RATE=$(( (H2_RX - H1_RX) / 3 ))
  H_TX_RATE=$(( (H2_TX - H1_TX) / 3 ))
  echo "3) Host rate (3s window) rx=${H_RX_RATE} B/s tx=${H_TX_RATE} B/s"
else
  echo "2) flatpak-spawn not found — cannot read host /proc"
fi

read -r SB2_RX SB2_TX < <(read_counter sandbox "$SANDBOX_FILE")
SB_RX_RATE=$(( (SB2_RX - SB_RX) / 3 ))
SB_TX_RATE=$(( (SB2_TX - SB_TX) / 3 ))
echo "4) Sandbox rate (3s window) rx=${SB_RX_RATE} B/s tx=${SB_TX_RATE} B/s"
echo

if [[ -n "$SPAWN" && "$H1_RX" -gt 100000000 && "$SB_RX" -lt 10000000 ]]; then
  echo "PROVEN: host counters are host-scale; sandbox counters are namespace-scale."
  echo "The fix (networkProcFileContents → flatpak-spawn host cat) reads source 2/3, not 1/4."
elif [[ -n "$SPAWN" && "$H_RX_RATE" -gt 1024 && "$SB_RX_RATE" -lt 256 ]]; then
  echo "PROVEN: host rate reflects real traffic; sandbox rate stays in single/double digits."
else
  echo "INCONCLUSIVE: generate traffic (stream/download) and re-run, or check interface name (${IFACE})."
fi
