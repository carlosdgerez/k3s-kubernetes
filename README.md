
## Components
<p align="center">
  <img src="images/Diagram.png" alt="Architecture Diagram" width="100%">
</p>
Cloud-Native Three-Tier Web Application Deployment on K3s
</h1>

<p align="center">
<h1 align="center">

Kubernetes • K3s • Docker • Redis • MySQL • Vagrant • VirtualBox
</p>









<h4>
A cloud-native deployment of the Question2Answer (Q2A) platform running on a multi-node K3s Kubernetes cluster provisioned with Vagrant and VirtualBox.</h4>

This project demonstrates infrastructure automation, containerization, Kubernetes orchestration, persistent storage management, distributed session handling, and scalable application deployment within a locally hosted Kubernetes environment.

---

# Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
  - [Network Topology](#network-topology)
  - [Component Interactions](#component-interactions)
- [Technology Stack](#technology-stack)
- [Key Features](#key-features)
- [Deployment](#deployment)
- [Repository Structure](#repository-structure)
- [Issues solved](#the-multi-node-network-isolation-challenge-the-host-fix-script)
- [Future Improvements](#future-improvements)

---

## Overview

The application follows a classic three-tier architecture:

- Presentation Layer – Question2Answer PHP/Apache application
- Application & Session Layer – Redis session store
- Data Layer – MySQL database with persistent storage

---

## Architecture

### Network Topology

```mermaid
flowchart TB

    User["Browser / Client"]

    subgraph Host["VirtualBox Host Network (192.168.56.0/24)"]
        Server["k3s-server
        192.168.56.10"]

        Worker1["k3s-worker-1
        192.168.56.11"]

        Worker2["k3s-worker-2
        192.168.56.12"]
    end

    User -->|"HTTP :30080"| Server

    Server <--> Worker1
    Server <--> Worker2

    NodePort["NodePort Service
    30080"]

    Server --> NodePort

    NodePort --> Pods["Q2A Deployment
    5 Replicas"]
```

### Component Interactions

```mermaid
flowchart LR

    Client["User Browser"]

    Proxy["NodePort Service
    Session Affinity"]

    subgraph App["Q2A Application Tier"]
        Pod1["Q2A Pod 1"]
        Pod2["Q2A Pod 2"]
        Pod3["Q2A Pod 3"]
        Pod4["Q2A Pod 4"]
        Pod5["Q2A Pod 5"]
    end

    Redis["Redis Session Store"]
    MySQL["MySQL StatefulSet PVC Storage"]

    Client --> Proxy

    Proxy --> Pod1
    Proxy --> Pod2
    Proxy --> Pod3
    Proxy --> Pod4
    Proxy --> Pod5

    Pod1 --> Redis
    Pod2 --> Redis
    Pod3 --> Redis
    Pod4 --> Redis
    Pod5 --> Redis

    Pod1 --> MySQL
    Pod2 --> MySQL
    Pod3 --> MySQL
    Pod4 --> MySQL
    Pod5 --> MySQL
```

## Technology Stack

| Component | Technology |
|------------|------------|
| Container Runtime | Docker |
| Orchestration | K3s Kubernetes |
| Provisioning | Vagrant |
| Virtualization | VirtualBox |
| Application | Question2Answer |
| Web Server | Apache |
| Language | PHP 8.1 |
| Database | MySQL |
| Session Store | Redis |
| Operating System | Ubuntu 22.04 |

## Key Features

- Multi-node K3s cluster
- 5-replica Q2A deployment
- Redis-backed distributed sessions
- MySQL StatefulSet with persistent storage
- Infrastructure as Code with Vagrant
- Custom Docker image build
- Session affinity load balancing

## Deployment

```bash
vagrant up
kubectl apply -f kubernetes.yaml
kubectl get pods
kubectl get services
```

Access:

```text
http://<NODE-IP>:30080
```

## Repository Structure

```text
.
├── Vagrantfile
├── kubernetes.yaml
├── Dockerfile
├── entrypoint.sh
├── scripts/
│   ├── setup-server.sh
│   └── setup-agent.sh
└── fix-host-network.sh
```


---

## The Multi-Node Network Isolation Challenge (The Host Fix Script)

### The Issue
When setting up a multi-node Kubernetes cluster via Vagrant using VirtualBox's default Private Host-Only networking (`vboxnet`), a standard operating system routing conflict can isolate the cluster agents. The host OS or virtualization bridge often defaults to processing traffic through your primary home network gateway rather than keeping node-to-node packets inside the isolated private subnet. This breaks Flannel VXLAN pod routing, leaving worker nodes unable to communicate or join the master node correctly.

### The Automated Solution (`fix-host-network.sh`)
To resolve this without manual hypervisor point-and-click intervention, this repository utilizes an automated network orchestration script. The script identifies the host's virtual adapter boundaries, flushes stale local routing entries, and rebuilds the private virtual network bridge with explicit metrics. This guarantees seamless node-to-node telemetry.

### Configuration Template
Since environment-specific parameters (such as physical interface names) are ignored by Git for security, copy the tracked template to replicate this fix in your local lab environment:

```bash
cp fix-host-network.sh.example fix-host-network.sh
chmod +x fix-host-network.sh
```
```bash
#!/usr/bin/env bash
# =========================================================================
# Host Network Resolution Script (Sanitized Template)
# Fixes routing conflicts between the Host OS and VirtualBox Host-Only interfaces
# =========================================================================

set -euo pipefail

# --- Environment Configurations (Modify to match your local setup) ---
VBOX_INTERFACE="vboxnet0"
TARGET_SUBNET="192.168.XX.0/24"  # ◄── Replace with your private cluster subnet
GATEWAY_IP="192.168.XX.1"       # ◄── Replace with your host bridge interface gateway IP

echo "[*] Auditing local virtualization network routing entries..."

# 1. Clear conflicting interfaces or stale IP assignments
if ip link show "$VBOX_INTERFACE" >/dev/null 2>&1; then
    echo "[!] Found active interface $VBOX_INTERFACE. Flushing stale routing tables..."
    sudo ip addr flush dev "$VBOX_INTERFACE"
    sudo ip link set "$VBOX_INTERFACE" down
fi

# 2. Re-initialize physical virtual adapter state
echo "[*] Re-enabling $VBOX_INTERFACE interface..."
sudo ip link set "$VBOX_INTERFACE" up
sudo ip addr add "$GATEWAY_IP/24" dev "$VBOX_INTERFACE"

# 3. Force precise subnet isolation routes
echo "[*] Enforcing isolated route metrics for cluster subnet..."
sudo ip route replace "$TARGET_SUBNET" dev "$VBOX_INTERFACE" proto kernel scope link src "$GATEWAY_IP" metric 10

echo "[🎉] Host network isolation resolved. Run 'vagrant up' to provision the cluster."
```

# 🚀 Automated Multi-Tier Deployment & Troubleshooting

This section documents the evolution of the project into a lightweight nested virtualization environment located in the `light-wsl2-kvm/` directory. This deployment replaces the original VirtualBox-based lab with a KVM-powered Kubernetes environment running inside WSL2 while preserving the same three-tier Q2A architecture.

## Light WSL2-KVM Architecture

```text
light-wsl2-kvm/
├── manifests/
│   ├── 00-storage-provisioner.yaml
│   ├── 01-q2a-secrets.yaml
│   └── 02-q2a-three-tier.yaml
├── scripts/
├── cloud-init/
└── README.md
```

The deployment stack consists of:

* Q2A PHP application tier
* Redis distributed session layer
* MySQL StatefulSet database
* Dynamic local persistent storage
* Kubernetes-native secret management
* Automated manifest orchestration

---

## Manifest Architecture & Single-Command Deployment

To improve maintainability and simplify lifecycle management, the deployment is split into modular manifests that Kubernetes processes alphabetically.

```text
manifests/
├── 00-storage-provisioner.yaml  # Dynamic storage provisioning
├── 01-q2a-secrets.yaml          # Application secrets and credentials
└── 02-q2a-three-tier.yaml       # MySQL, Redis, and Q2A workloads
```

### Deploy Entire Stack

```bash
kubectl apply -f manifests/
```

### Remove Entire Stack

```bash
kubectl delete -f manifests/
```

This approach allows the complete application platform to be deployed or removed using a single command while preserving separation of concerns between storage, security, and application layers.

---

# 🔧 Troubleshooting & Operational Lessons Learned

## 1. Dynamic Storage Provisioning for Stateful Workloads

### Symptom

The MySQL StatefulSet pod remained permanently in a `Pending` state:

```bash
kubectl get pods
```

Output:

```text
internal-db-0   Pending
```

### Root Cause

Pod inspection revealed unresolved PersistentVolumeClaims:

```bash
kubectl describe pod internal-db-0
```

Event output:

```text
0/3 nodes are available:
pod has unbound immediate PersistentVolumeClaims
```

Further investigation showed that no default StorageClass existed:

```bash
kubectl get storageclass
```

Output:

```text
No resources found
```

### Resolution

A standalone Rancher Local Path Provisioner was deployed as the cluster's dynamic storage backend.

```yaml
metadata:
  name: local-path
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
```

After installation, PersistentVolumeClaims automatically bound to node-local storage and the StatefulSet transitioned to a healthy running state.

### Verification

```bash
kubectl get pvc
kubectl get pv
kubectl get pods
```

Expected result:

```text
STATUS: Bound
STATUS: Running
```

---

## 2. Service Discovery & Database Connectivity Validation

### Symptom

Application containers failed startup with:

```text
Could not establish database connection
```

### Root Cause

The Kubernetes Service was not correctly matching the target database pods.

Endpoint inspection revealed:

```bash
kubectl get endpoints db
```

Output:

```text
<none>
```

This indicated a mismatch between Service selectors and Pod labels.

### Resolution

Standardized selectors and labels across all application resources to ensure proper endpoint registration.

### Connectivity Verification

Validate database reachability directly from an application container:

```bash
kubectl exec -it deployment/q2a-app -- \
timeout 2 bash -c '</dev/tcp/db/3306 && echo "PORT 3306 IS OPEN"'
```

Expected result:

```text
PORT 3306 IS OPEN
```

This confirms successful service discovery and TCP connectivity between the application and database tiers.

---

# 🌐 Development Access vs Production Networking

During development, nested network isolation between Windows, WSL2, and the private KVM bridge network required temporary port forwarding.

A lightweight relay was implemented using `socat`:

```bash
sudo socat \
TCP4-LISTEN:8080,fork,reuseaddr \
TCP4:192.168.100.10:30080 &
```

### Current Development Flow

```text
Browser
    ↓
localhost:8080
    ↓
socat relay
    ↓
NodePort 30080
    ↓
Q2A Application Pods
```

This provided local browser access without modifying cluster networking components.

---

# 🎯 Next Infrastructure Milestone

The current relay-based approach is suitable for development and troubleshooting but is not intended for production use.

Future iterations will replace this transport layer with:

* MetalLB Layer 2 Load Balancing
* Kubernetes Ingress Controller
* TLS termination
* DNS-based routing
* Production-grade traffic management

Target architecture:

```text
Client
   ↓
MetalLB
   ↓
Ingress Controller
   ↓
Q2A Application Services
   ↓
Redis + MySQL Backend Services
```

This will provide a fully cloud-native bare-metal deployment model without requiring local forwarding utilities.


## Future Improvements

- Ingress Controller
- TLS with cert-manager
- Horizontal Pod Autoscaler
- Monitoring with Prometheus and Grafana
- MySQL replication
- GitHub Actions CI/CD
