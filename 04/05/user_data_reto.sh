#!/bin/bash
set -euxo pipefail

apt-get update -y
apt-get install -y ca-certificates curl

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

mkdir -p /var/www/html
cat > /var/www/html/index.html <<'EOFHTML'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>EC2 + User Data + Docker</title>
</head>
<body>
  <h1>Servidor provisionado automáticamente</h1>
  <p>EC2 + User Data + Docker</p>
</body>
</html>
EOFHTML

docker run -d --name web -p 80:80 -v /var/www/html:/usr/share/nginx/html:ro nginx:alpine
