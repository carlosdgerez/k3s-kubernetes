#!/usr/bin/env bash

# Wait up to 30 seconds for virbr2 to be created by libvirt/Vagrant
echo "Waiting for virbr2 interface to become available..."
for i in {1..30}; do
    if ip link show dev virbr2 >/dev/null 2>&1; then
        echo "virbr2 is up!"
        break
    fi
    sleep 1
done

# 1. Base Routing & Reverse Path Parameters
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.rp_filter=2
sysctl -w net.ipv4.conf.default.rp_filter=2
sysctl -w net.ipv4.conf.eth0.rp_filter=2
sysctl -w net.ipv4.conf.virbr2.rp_filter=2
sysctl -w net.ipv4.conf.eth0.proxy_arp=1
sysctl -w net.ipv4.conf.virbr2.proxy_arp=1

# 2. Local Point-to-Point Listener Alignment
#ip addr add 192.168.100.1/32 dev eth0 2>/dev/null || true

# 3. Connection Tracking & Filter Overrides for Libvirt
iptables -t raw -I PREROUTING 1 -s 172.29.0.0/20 -d 192.168.100.0/24 -j NOTRACK 2>/dev/null || true
iptables -t raw -I PREROUTING 2 -s 192.168.100.0/24 -d 172.29.0.0/20 -j NOTRACK 2>/dev/null || true
iptables -I FORWARD 1 -s 172.29.0.0/20 -d 192.168.100.0/24 -j ACCEPT 2>/dev/null || true
iptables -I FORWARD 2 -s 192.168.100.0/24 -d 172.29.0.0/20 -j ACCEPT 2>/dev/null || true

# Allow inbound to the bridge VMs
iptables -I LIBVIRT_FWI 1 -d 192.168.100.0/24 -o virbr2 -j ACCEPT 2>/dev/null || true

# Fix the missing link: Allow outbound replies from the bridge VMs back to WSL2/Windows
iptables -I LIBVIRT_FWO 1 -s 192.168.100.0/24 -i virbr2 -j ACCEPT 2>/dev/null || true


# Allow Kubernetes internal pod network & cluster interfaces to pass traffic freely
iptables -A FORWARD -i cni0 -j ACCEPT 2>/dev/null || true
iptables -A FORWARD -o cni0 -j ACCEPT 2>/dev/null || true
iptables -A FORWARD -i flannel.1 -j ACCEPT 2>/dev/null || true
iptables -A FORWARD -o flannel.1 -j ACCEPT 2>/dev/null || true


echo "[🎉] Kernel network optimizations applied successfully!"