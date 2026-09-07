#!/bin/bash
TARGET=${1:-logs/access.log}

if [ ! -f "$TARGET" ]; then
    echo "Archivo $TARGET no encontrado."
    exit 1
fi

echo "=== ANÁLISIS DE REGISTROS EN TIEMPO REAL ($TARGET) ==="
echo "Total de accesos registrados : $(wc -l < "$TARGET")"
echo "Errores detectados           : $(grep -c ' 404 \| 500 ' "$TARGET" 2>/dev/null || echo 0)"
echo "Últimos registros:"
tail -n 5 "$TARGET"