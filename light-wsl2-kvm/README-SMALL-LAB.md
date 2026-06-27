## 📌 Table of Contents

* [🚀 Getting Started](#-getting-started)
  * [📋 Prerequisites](#-prerequisites)
  * [🛠️ Spinning Up the Lab](#️-spinning-up-the-lab)
  * [🌐 Accessing the Application](#-accessing-the-application)
  * [🧹 Tearing Down the Lab](#-tearing-down-the-lab)
* [🚀 Automated Multi-Tier Deployment & Troubleshooting](#-automated-multi-tier-deployment--troubleshooting)
  * [Light WSL2-KVM Architecture](#light-wsl2-kvm-architecture)
  * [Manifest Architecture & Single-Command Deployment](#manifest-architecture--single-command-deployment)
* [🔧 Troubleshooting & Operational Lessons Learned](#-troubleshooting--operational-lessons-learned)
  * [1. Dynamic Storage Provisioning for Stateful Workloads](#1-dynamic-storage-provisioning-for-stateful-workloads)
  * [2. Service Discovery & Database Connectivity Validation](#2-service-discovery--database-connectivity-validation)
* [🌐 Development Access vs Production Networking](#-development-access-vs-production-networking)
* [🎯 Next Infrastructure Milestone](#-next-infrastructure-milestone)
  * [🌐 WSL2 & KVM Ingress Gateway (NGINX Reverse Proxy Architecture)](#-wsl2--kvm-ingress-gateway-nginx-reverse-proxy-architecture)
  * [⚙️ Automation & Deployment Lifecycle](#️-automation--deployment-lifecycle)
  * [🎯 Verification](#-verification)

---



## 🚀 Getting Started

This repository provides a fully automated, lightweight 3-tier Kubernetes laboratory environment running **K3s** across local **WSL2** and **KVM/Libvirt** virtual machines. 

The infrastructure features a dedicated NGINX host-routing bridge to seamlessly handle asymmetric Layer 4 traffic routing between Windows and the virtualized cluster network, alongside a MetalLB Layer 2 load balancer.

### 📋 Prerequisites

Before spinning up the cluster, ensure your local WSL2 Ubuntu terminal session has proper administrative permissions to interact with the local virtualization daemon:

```bash
# 1. Add your user account to the virtualization security groups
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# 2. Refresh your current terminal session groups immediately
newgrp libvirt
```
### 🛠️ Spinning Up the Lab

We have unified the entire infrastructure lifecycle, secure credential synchronization, and application manifest deployment into a single startup script.

To stand up the database, Redis caching layer, and Question2Answer (Q2A) application from a cold start, run the following command from the root of this directory:

```bash
./start-lab.sh
```
What this automated pipeline does for you:
1. `vagrant up` — Provisions the virtual master (k3s-server) and worker nodes (k3s-agent-1, k3s-agent-2), handles local bridge bindings, and runs host-level network optimization scripts.
2. `./scripts/verify-lab.sh` Securely extracts the fresh cluster authentication tokens from the master VM, updates your local `~/.kubeconfig.yaml` , and realigns the Kubernetes API endpoint.
3. `kubectl apply -f manifests/` — Automatically deploys your storage provisioners, local cluster secrets, high-availability deployments, and MetalLB configurations in their exact sequence. The last lines will trow an error the first time it runs because the pods are not yet ready to receive their ip addresses. Wait one minute and run again `kubectl apply -f manifests/`. This second time will not trow errors. 

### 🌐 Accessing the Application

Once the startup script confirms all pods have transitioned to a 1/1 Running state, open your Windows browser and navigate to the application installation and initialization path:
```text
http://172.29.15.185:8080
```




### 🧹 Tearing Down the Lab

To completely stop the virtual machines and wipe out all temporary local runtime states without losing your project configurations, run:

```bash
vagrant destroy -f
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

### 🌐 Development Access vs Production Networking

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
 
```text
/k3s-kubernetes/
├── Vagrantfile                # Deploys 3 KVM virtual cluster machines
├── kubeconfig.yaml            # Secret credentials (ignored by Git)
├── setup-network-route.ps1     # ◄── NEW: Automates the Windows-to-KVM networking bridge
└── manifests/
            ├── 00-storage-provisioner.yaml  # Dynamic storage provisioning
            ├── 01-secrets.yaml              # Application secrets and credentials
            ├── 02-q2a-three-tier.yaml       # MySQL, Redis, and Q2A workloads 
            ├── 03-metallb-core.yaml         # Metallb core
            └── 04-metallb-config.yaml       # Metallb configuration workloads                


```
## 🌐 WSL2 & KVM Ingress Gateway (NGINX Reverse Proxy Architecture)

### 🚨 The Problem: Layer 3 Asymmetric Routing Loop

When exposing a nested KVM Kubernetes cluster (managed via `libvirt` inside WSL2) to a Windows 11 host, traditional IP routing protocols fail at the Network Layer (Layer 4 vs Layer 3). 

Using traditional static routes (`route ADD`) forces network packets to traverse conflicting kernel boundaries:

1. **Inbound Path:** Windows sends a request to the WSL2 virtual interface IP, which forwards it into the private KVM network bridge (`k3s-private-net`) targeting the MetalLB LoadBalancer service (`192.168.100.200:80`).
2. **The Asymmetric Return Trap:** When the K3s cluster node replies, it detects that the source IP belongs to the Windows Host (`172.x.x.x`). Instead of routing the reply back through the ingress interface path, the node takes a routing shortcut through the default gateway path. 
3. **The Result:** The TCP connection drops immediately because the Windows host receives a return packet from an unexpected IP address, causing a silent connection timeout or reset.

---

### 🛡️ The Solution: Layer 4 Connection Termination

To cleanly break this routing loop, this repository implements an automated **NGINX Reverse Proxy Gateway** operating in **TCP Stream Mode (Layer 4)** directly inside the WSL2 user space.
 Instead of simply forwarding raw network packets down the wire, NGINX acts as a circuit breaker:
* **Connection Termination:** NGINX handles the incoming TCP connection from Windows on port `8080` and completely terminates it inside the WSL2 kernel space.
* **A New Session:** NGINX opens a *completely separate, brand-new TCP socket request* targeting the MetalLB External IP (`192.168.100.200:80`).
* **Symmetric Return:** Because the request originates directly from the local WSL2 user space, the KVM cluster nodes recognize the source IP as the local WSL2 gateway interface. Packets are forced to return along the exact same path they arrived, ensuring stable connection handshakes and eliminating database/Redis state drops.

```text
+-------------------+             (Connection 1)             +-------------------------+
|   Windows 11      | -------------------------------------> | WSL2 Kernel (Port 8080) |
|  (Web Browser /   | <------------------------------------- |  NGINX Stream Engine    |
|   PowerShell)     |         Symmetric Return Path          +-------------------------+
+-------------------+                                                     |
| (Connection 2)
v
+-------------------+                                        +-------------------------+
| K3s Worker Node   | <------------------------------------- | MetalLB LoadBalancer    |
| (Q2A Apache Pods) |         Symmetric Return Path          |    (192.168.100.200:80) |
+-------------------+                                        +-------------------------+
```
---

### ⚙️ Automation & Deployment Lifecycle

The NGINX gateway proxy configuration is entirely automated using a decoupled script infrastructure inside the Vagrant execution lifecycle.

#### 1. The Gateway Provisioning Script (`scripts/setup-nginx-gateway.sh`)
This script executes inside the host environment to isolate dynamic modules, construct a clean Stream configuration block, and handle service reloading:

```bash
#!/usr/bin/env bash
set -e

# Install NGINX and the Layer 4 Stream module if missing
if ! dpkg -s nginx libnginx-mod-stream >/dev/null 2>&1; then
    apt-get update && apt-get install -y nginx libnginx-mod-stream
fi

# Write isolated reverse proxy configurations
cat << 'EOF' > /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
}

stream {
    upstream q2a_cluster {
        server 192.168.100.200:80;
    }

    server {
        listen 8080;
        proxy_pass q2a_cluster;
        proxy_timeout 3m;
        proxy_connect_timeout 5s;
    }
}
EOF

systemctl restart nginx
```
### 🔌 Vagrant Integration (`Vagrantfile`)

The script is hooked at the root level of the `Vagrantfile`, completely outside the cluster node loop. This guarantees that it fires exactly once as a post-deployment phase after all K3s server and agent nodes are healthy and the cluster is fully accessible.
```ruby
Vagrant.configure("2") do |config|
  
  # ... Individual Node Definitions Loop (k3s-server, k3s-agents) ...

  # Post-Deployment Ingress Layer Automation
  config.vm.provision "shell", 
    run: "always", 
    privileged: true, 
    path: "scripts/setup-nginx-gateway.sh"
end
```
# Verify Layer 4 TCP Handshake Response from Windows 
```PowerShell
curl.exe -I http://<WSL2_IP_ADDRESS>:8080
```
---

### 🎯 Verification

Once the stack is provisioned using `vagrant up`, test your external connectivity directly from Windows without altering host network adapters:

```PowerShell
# Verify Layer 4 TCP Handshake Response from Windows PowerShell

curl.exe -I http://<WSL2_IP_ADDRESS>:8080
```