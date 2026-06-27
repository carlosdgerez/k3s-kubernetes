#!/usr/bin/env bash
set -e

echo "=================================================="
echo "🚀 DevOps Automation: Configuring NGINX Gateway"
echo "=================================================="

# 1. Install NGINX and the Layer 4 Stream module if missing
if ! dpkg -s nginx libnginx-mod-stream >/dev/null 2>&1; then
    echo "📦 Installing NGINX and Stream Module..."
    apt-get update && apt-get install -y nginx libnginx-mod-stream
fi

# 2. Write the clean, isolated reverse proxy configuration
echo "✍️  Writing nginx.conf..."
cat << 'EOF' > /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

http {
    # Main loop default fallback configs
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
}

stream {
    upstream q2a_cluster {
        # Points directly to your internal MetalLB LoadBalancer IP
        server 192.168.100.200:80;
    }

    server {
        # Binds cleanly to port 8080 on the WSL2 kernel
        listen 8080;
        proxy_pass q2a_cluster;
        proxy_timeout 3m;
        proxy_connect_timeout 5s;
    }
}
EOF

# 3. Reload the service to spin up the proxy path
echo "🔄 Restarting NGINX Service..."
systemctl restart nginx
echo "✅ NGINX Reverse Proxy Gateway is active on port 8080!"