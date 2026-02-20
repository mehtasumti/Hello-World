#!/bin/bash
# ============================================================
# EC2 User Data Script - Hello World Nginx Setup
# Compatible with Amazon Linux 2023 and Ubuntu 22.04/24.04
# ============================================================

set -e
LOG_FILE="/var/log/userdata.log"
exec > >(tee -a $LOG_FILE) 2>&1
echo "=== User Data Script Started: $(date) ==="

# ── Detect OS ────────────────────────────────────────────────
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS="unknown"
fi
echo "Detected OS: $OS"

# ── Install Nginx ─────────────────────────────────────────────
if [ "$OS" = "amzn" ]; then
    # Amazon Linux 2023
    dnf update -y
    dnf install -y nginx
    systemctl enable nginx
elif [ "$OS" = "ubuntu" ]; then
    # Ubuntu
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
else
    echo "Unsupported OS: $OS" && exit 1
fi

# ── Fetch IMDSv2 Metadata ─────────────────────────────────────
TOKEN=$(curl -sf -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/local-ipv4)
REGION="${AZ::-1}"  # Strip last character (a/b) to get region

echo "Instance ID: $INSTANCE_ID | AZ: $AZ | Region: $REGION"

# ── Deploy HTML Page ──────────────────────────────────────────
WEB_ROOT="/usr/share/nginx/html"
cat > "${WEB_ROOT}/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello World - AWS DevOps Assessment</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #ffffff;
        }
        .container {
            text-align: center;
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 20px;
            padding: 50px 60px;
            max-width: 600px;
            width: 90%;
        }
        .badge { display:inline-block; background:#FF9900; color:#000;
            font-size:12px; font-weight:700; padding:4px 12px;
            border-radius:20px; margin-bottom:20px; }
        h1 { font-size:3.5rem; font-weight:700; margin-bottom:10px;
            background:linear-gradient(90deg,#FF9900,#ffcc66);
            -webkit-background-clip:text; -webkit-text-fill-color:transparent; }
        .subtitle { color:rgba(255,255,255,0.6); margin-bottom:40px; }
        .info-card { background:rgba(255,153,0,0.08);
            border:1px solid rgba(255,153,0,0.3);
            border-radius:12px; padding:24px; }
        .info-row { display:flex; justify-content:space-between;
            padding:10px 0; border-bottom:1px solid rgba(255,255,255,0.05); }
        .info-row:last-child { border-bottom:none; }
        .label { color:rgba(255,255,255,0.5); font-size:0.85rem; text-transform:uppercase; }
        .value { font-weight:600; color:#ffcc66; font-family:monospace; }
        .pulse { display:inline-block; width:8px; height:8px; background:#00ff88;
            border-radius:50%; margin-right:6px;
            animation:pulse 2s infinite; }
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.5} }
        footer { margin-top:30px; color:rgba(255,255,255,0.4); font-size:0.85rem; }
    </style>
</head>
<body>
<div class="container">
    <div class="badge">☁️ AWS Infrastructure</div>
    <h1>Hello World!</h1>
    <p class="subtitle">Running on Amazon Web Services</p>
    <div class="info-card">
        <div class="info-row">
            <span class="label">Instance ID</span>
            <span class="value">${INSTANCE_ID}</span>
        </div>
        <div class="info-row">
            <span class="label">Availability Zone</span>
            <span class="value">${AZ}</span>
        </div>
        <div class="info-row">
            <span class="label">Region</span>
            <span class="value">${REGION}</span>
        </div>
        <div class="info-row">
            <span class="label">Private IP</span>
            <span class="value">${PRIVATE_IP}</span>
        </div>
        <div class="info-row">
            <span class="label">Status</span>
            <span class="value"><span class="pulse"></span>Healthy</span>
        </div>
    </div>
    <footer>Served by <strong style="color:#009639">Nginx</strong> · Deployed via ALB</footer>
</div>
</body>
</html>
EOF

# ── Write Nginx Config ────────────────────────────────────────
cat > /etc/nginx/conf.d/hello-world.conf <<'NGINX'
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    location / {
        try_files $uri $uri/ =404;
    }

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
}
NGINX

# Remove default config if it conflicts
if [ "$OS" = "amzn" ]; then
    rm -f /etc/nginx/conf.d/default.conf
elif [ "$OS" = "ubuntu" ]; then
    rm -f /etc/nginx/sites-enabled/default
fi

# ── Test and Start Nginx ──────────────────────────────────────
nginx -t && systemctl restart nginx
echo "=== User Data Script Completed: $(date) ==="
