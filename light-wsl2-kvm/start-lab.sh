#!/usr/bin/env bash

# Exit immediately if any command fails
set -e

echo "===================================================="
echo "🚀 Starting Kubernetes Lab Infrastructure..."
echo "===================================================="

# Step 1: Boot up the virtual machines via Vagrant
echo "⚡ Step 1: Spinning up KVM virtual machines..."
vagrant up

# Step 2: Extract credentials and align host networking
echo "🔒 Step 2: Running verify-lab.sh to sync cluster configs..."
./verify-lab.sh

# Step 3: Apply your application manifests
echo "📦 Step 3: Deploying application manifests to K3s..."
kubectl apply -f manifests/

echo "===================================================="
echo "🎉 Cluster initialized! Monitoring pod startup..."
echo "👉 Press Ctrl+C at any time to exit monitoring."
echo "===================================================="

# Step 4: Automatically monitor pod state until they are ready
kubectl get pods -w