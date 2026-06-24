#!/usr/bin/env bash
set -euo pipefail

NODE_NAME=$1
NODE_IP=$2

# Check if either k3s or k3s-agent service is already running
if systemctl is-active --quiet k3s || systemctl is-active --quiet k3s-agent; then
  echo "[i] K3s Agent service on ${NODE_NAME} is already running. Skipping registration."
else
  echo "[*] Registering Worker Node ${NODE_NAME} at ${NODE_IP}..."
  curl -sfL https://get.k3s.io | K3S_URL="https://192.168.100.10:6443" K3S_TOKEN="K3sSecretClusterToken123!" sh -s - \
    --node-ip=#{node_meta[:ip]} \
    --flannel-iface=eth1
fi