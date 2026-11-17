#!/bin/bash
set -euxo pipefail

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

systemctl enable nginx
systemctl start nginx

cat > /var/www/html/index.html <<'EOFHTML'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>EC2 + User Data</title>
</head>
<body>
  <h1>Servidor provisionado automáticamente</h1>
  <p>EC2 + User Data</p>
</body>
</html>
EOFHTML
