#!/bin/bash

UMBRAL_DISCO=80

echo "==================== MONITOR DEL SISTEMA ===================="
echo "Hostname            : $(hostname)"
echo "Usuario actual      : $(whoami)"
echo "Fecha y hora        : $(date '+%Y-%m-%d %H:%M:%S')"
echo "Directorio actual   : $(pwd)"
echo "Procesos activos    : $(($(ps -ef | wc -l) - 1))"
echo "------------------------------------------------------------"

echo "ESTADO DEL ALMACENAMIENTO (df -h):"
df -h
echo "------------------------------------------------------------"

echo "VERIFICACIÓN DE CAPACIDAD (Umbral: ${UMBRAL_DISCO}%):"
ALERTA=0
# Se procesa df excluyendo encabezados y sistemas de archivos temporales
while read -r uso particion; do
    porcentaje=${uso%\%}
    if [ "$porcentaje" -ge "$UMBRAL_DISCO" ]; then
        echo "[ADVERTENCIA CRÍTICA] La partición '$particion' ha alcanzado el ${porcentaje}% de uso."
        ALERTA=1
    fi
done < <(df -hP | awk 'NR>1 && $1 !~ /tmpfs|udev/ {print $5, $6}')

if [ "$ALERTA" -eq 0 ]; then
    echo "Todas las particiones se encuentran dentro de los márgenes seguros."
fi

echo "============================================================"
echo "Diagnóstico finalizado con éxito."
exit 0
EOF
