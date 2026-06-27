#!/usr/bin/env bash
set -e # Exit immediately if a command fails

# Text Colors for Scannable Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}======================================================${NC}"
echo -e "${YELLOW}🚀 STARTING SYSTEMATIC K3S LAB CONNECTIVITY VERIFIER  ${NC}"
echo -e "${YELLOW}======================================================${NC}"

# -------------------------------------------------------------------------
# STEP 1: Execute Kernel Network Configurations
# -------------------------------------------------------------------------
echo -e "\n${YELLOW}[Step 1/5] Applying Layer 3 Proxy ARP & Firewall Configurations...${NC}"
SCRIPTS_DIR="$(pwd)/scripts"

if [ -f "$SCRIPTS_DIR/sysctl-networking.sh" ]; then
    chmod +x "$SCRIPTS_DIR/sysctl-networking.sh"
    sed -i 's/\r$//' "$SCRIPTS_DIR/sysctl-networking.sh"
    echo "Executing sysctl-networking.sh with root privileges..."
    sudo "$SCRIPTS_DIR/sysctl-networking.sh"
else
    echo -e "${RED}❌ Error: scripts/sysctl-networking.sh not found in this directory!${NC}"
    exit 1
fi

# -------------------------------------------------------------------------
# STEP 2: Verify Local Linux Routing and Interfaces
# -------------------------------------------------------------------------
echo -e "\n${YELLOW}[Step 2/5] Validating Linux Kernel Network Telemetry...${NC}"

# Check for /32 Point-to-Point Address Alias
if ip addr show dev eth0 | grep -q "192.168.100.1/32"; then
    echo -e "${GREEN}✓ Interface eth0 correctly holds the 192.168.100.1/32 point-to-point alias.${NC}"
else
    echo -e "${RED}❌ Interface eth0 is missing the 192.168.100.1/32 alias.${NC}"
    exit 1
fi

# Check active kernel routing mapping path
ROUTE_CHECK=$(ip route get 192.168.100.10)
if [[ "$ROUTE_CHECK" == *"dev virbr2"* ]]; then
    echo -e "${GREEN}✓ Kernel Route Check Passed: Traffic to 192.168.100.10 binds to dev virbr2.${NC}"
else
    echo -e "${RED}❌ Kernel Route Check Failed: Route is misaligned.${NC}"
    exit 1
fi

# -------------------------------------------------------------------------
# STEP 3: Low-Level Transport Layer ICMP Verification
# -------------------------------------------------------------------------
echo -e "\n${YELLOW}[Step 3/5] Verifying Layer 3 ICMP Path to Control Plane VM...${NC}"
if ping -c 3 192.168.100.10 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ ICMP Transport verified! Local WSL2 partition can talk directly to 192.168.100.10.${NC}"
else
    echo -e "${RED}❌ Transport Blocked: Ping to 192.168.100.10 dropped. Check raw iptables filter chains.${NC}"
    exit 1
fi

# -------------------------------------------------------------------------
# STEP 4: Pull & Build Kubeconfig Infrastructure
# -------------------------------------------------------------------------
echo -e "\n${YELLOW}[Step 4/5] Syncing Kubeconfig from Control Plane...${NC}"
KUBECONFIG_FILE="$(pwd)/kubeconfig.yaml"

echo "Extracting raw cluster configuration metadata over Vagrant SSH link..."
vagrant ssh k3s-server -c "sudo cat /etc/rancher/k3s/k3s.yaml" > "$KUBECONFIG_FILE"

echo "Modifying endpoint map: replacing 127.0.0.1 loopback with 192.168.100.10..."
sed -i 's/127.0.0.1/192.168.100.10/g' "$KUBECONFIG_FILE"
chmod 600 "$KUBECONFIG_FILE"
echo -e "${GREEN}✓ Local configuration file built successfully at: $KUBECONFIG_FILE${NC}"

# -------------------------------------------------------------------------
# STEP 5: Environment Variable Export Mapping
# -------------------------------------------------------------------------
echo -e "\n${YELLOW}[Step 5/5] Mapping Runtime Environment Context Variables...${NC}"
export KUBECONFIG="$KUBECONFIG_FILE"

# Append permanently to shell profile if not already tracked
if ! grep -q "export KUBECONFIG=\"$KUBECONFIG_FILE\"" ~/.bashrc; then
    echo "Adding permanent environment definition tracking to ~/.bashrc..."
    echo "export KUBECONFIG=\"$KUBECONFIG_FILE\"" >> ~/.bashrc
fi

echo -e "${GREEN}✓ Runtime shell configuration tracking path mapped!${NC}"
echo -e "${YELLOW}======================================================${NC}"
echo -e "${GREEN}🎉 ALL SYSTEMS DEPLOYED. RETRIEVING LIVE K3S STATUS: ${NC}"
echo -e "${YELLOW}======================================================${NC}"

echo "Executing terminal check"
kubectl get nodes