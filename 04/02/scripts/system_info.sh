#!/bin/bash

TARGET="${1:-/}"

echo "Hostname: $(hostname)"
echo "Usuario: $(whoami)"
echo "Fecha: $(date)"
echo "Uptime:"
uptime

echo
echo "Filesystem donde se encuentra $TARGET:"
df -hT "$TARGET"

echo
echo "Mount point:"
findmnt -T "$TARGET"

echo
echo "Memoria:"
free -h

echo
echo "Procesos con mayor uso de CPU:"
ps aux --sort=-%cpu | head -6
