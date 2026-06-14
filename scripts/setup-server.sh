#!/usr/bin/env bash
set -euo pipefail

NODE_IP=$1
echo "🚀 Preparing system network interfaces..."

# === NEW: Wait for eth1 to get its private IP assignment from Vagrant ===
echo "⏳ Waiting for eth1 to bind to ${NODE_IP}..."
while ! ip addr show dev eth1 | grep -q "${NODE_IP}"; do
  sleep 1
done
echo "✅ Network interface eth1 is up with IP ${NODE_IP}."

echo "🚀 Installing K3s Master Server..."
# Install K3s with the explicit interface (eth1 is confirmed correct)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=${NODE_IP} --flannel-iface=eth1 --write-kubeconfig-mode 644" sh -

# Wait for K3s to initialize and generate node-token
echo "⏳ Waiting for K3s to initialize and generate node-token..."
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 1
done

# Ensure the shared folder mount directory is present
sudo mkdir -p /vagrant

# Extract the cluster join token and save it to the shared Vagrant folder
sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token
echo "✅ Master Server is ready. Token exported."