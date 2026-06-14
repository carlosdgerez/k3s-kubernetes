#!/usr/bin/env bash
set -euo pipefail

NODE_IP=$1
MASTER_IP="192.168.56.10"
echo "🚀 Connecting K3s Worker Node on ${NODE_IP}..."

# Wait until the master server creates the shared node token file
while [ ! -f /vagrant/node-token ]; do
  echo "⏳ Waiting for master node-token file..."
  sleep 2
done

# Read the dynamic token from the shared directory
K3S_TOKEN=$(cat /vagrant/node-token)

# Install K3s Agent pointing to the Master IP using the explicit enp0s8 interface
curl -sfL https://get.k3s.io | K3S_URL="https://${MASTER_IP}:6443" K3S_TOKEN="${K3S_TOKEN}" INSTALL_K3S_EXEC="agent --node-ip=${NODE_IP} --flannel-iface=eth1" sh -
echo "✅ Worker successfully attached to the cluster."