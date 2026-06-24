#!/usr/bin/env bash
set -euo pipefail

# Accept runtime parameters passed by the Vagrant config loop
NODE_NAME="${1}"
NODE_IP="${2}"

echo "[*] Preparing environment configuration for ${NODE_NAME}..."
sudo mkdir -p /etc/rancher/k3s

cat <<EOF | sudo tee /etc/rancher/k3s/config.yaml
server: "https://192.168.100.10:6443"
token: "K3sSecretClusterToken123!"
node-ip: "${NODE_IP}"
flannel-iface: "eth1"
kube-proxy-arg:
  - "proxy-mode=ipvs"
  - "ipvs-strict-arp=true"
EOF

if [ -f /usr/local/bin/k3s-agent ] || [ -f /usr/local/bin/k3s ]; then
  echo "[i] K3s Worker Node agent is already installed. Validating running state..."
  sudo systemctl daemon-reload
  sudo systemctl restart k3s-agent 2>/dev/null || sudo systemctl restart k3s
else
  echo "[*] Initializing K3s Worker Registration..."
  curl -sfL https://get.k3s.io | K3S_URL="https://192.168.100.10:6443" K3S_TOKEN="K3sSecretClusterToken123!" sh -s - agent
fi

echo "[🎉] Worker node ${NODE_NAME} provisioning sequence verified!"