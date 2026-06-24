#!/usr/bin/env bash
set -euo pipefail

echo "==> Configuring production networking parameters for Kubernetes/MetalLB..."

# 1. Disable ICMP redirects to prevent routing loops with local bridge neighbors
sudo sysctl -w net.ipv4.conf.all.send_redirects=0
sudo sysctl -w net.ipv4.conf.default.send_redirects=0
sudo sysctl -w net.ipv4.conf.eth1.send_redirects=0
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
sudo sysctl -w net.ipv4.conf.default.accept_redirects=0
sudo sysctl -w net.ipv4.conf.eth1.accept_redirects=0

# 2. Set Reverse Path Filtering to Loose mode (Required for MetalLB Layer 2 asymmetric routing)
sudo sysctl -w net.ipv4.conf.all.rp_filter=2
sudo sysctl -w net.ipv4.conf.default.rp_filter=2
sudo sysctl -w net.ipv4.conf.eth1.rp_filter=2

# 3. Persist configurations across system reboots
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-metallb.conf
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.eth1.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.eth1.accept_redirects = 0
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
net.ipv4.conf.eth1.rp_filter = 2
EOF

echo "[🎉] Kernel network optimizations applied successfully!"