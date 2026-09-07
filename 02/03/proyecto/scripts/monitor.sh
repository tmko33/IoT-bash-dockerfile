#!/bin/bash
echo "=== REPORTE DE ESTADO DEL CONTENEDOR ==="
echo "Hostname : $(hostname)"
echo "Usuario  : $(whoami)"
echo "Fecha    : $(date '+%Y-%m-%d %H:%M:%S')"
echo "Directorio: $(pwd)"
echo -e "\nUso de disco:"
df -h /workspace
echo -e "\nProcesos activos:"
ps aux | wc -l
echo "=== FIN DEL DIAGNÓSTICO ==="