#!/usr/bin/env bash
set -euo pipefail

echo "[*] Ensuring K3s configuration layout directory exists..."
sudo mkdir -p /etc/rancher/k3s

echo "[*] Applying production configuration parameters..."
cat <<EOF | sudo tee /etc/rancher/k3s/config.yaml
token: "K3sSecretClusterToken123!"
disable:
  - traefik
  - local-storage
node-ip: "192.168.100.10"
tls-san: "192.168.100.10"
flannel-iface: "eth1"
kube-proxy-arg:
  - "proxy-mode=ipvs"
  - "ipvs-strict-arp=true"
EOF

if [ -f /usr/local/bin/k3s ]; then
  echo "[i] K3s Control Plane is already installed. Restarting daemon to apply modifications..."
  sudo systemctl daemon-reload
  sudo systemctl restart k3s
else
  echo "[*] Running fresh K3s Control Plane installation..."
  curl -sfL https://get.k3s.io | sh -s -
fi

until [ -f /etc/rancher/k3s/k3s.yaml ]; do sleep 1; done
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
echo "[🎉] K3s Control Plane engine is ready!"