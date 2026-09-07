#!/bin/bash

# Solicitar el nombre del directorio
read -p "Ingrese la ruta del directorio a respaldar: " dir_origen

# 1. Verificar que el directorio exista
if [ ! -d "$dir_origen" ]; then
    echo "ERROR: El directorio '$dir_origen' no existe."
    exit 1
fi

fecha=$(date +"%Y%m%d_%H%M%S")
nombre_backup="backup_$fecha.tar.gz"
archivo_log="backup.log"

# 2. Crear la carpeta backup si no existe
carpeta_backup="./backup"
mkdir -p "$carpeta_backup"

# 3. Comprimir el contenido usando tar
if tar -czf "$carpeta_backup/$nombre_backup" -C "$(dirname "$dir_origen")" "$(basename "$dir_origen")" 2>> "$archivo_log"; then
    
    # 4. Calcular estadísticas
    cantidad_archivos=$(tar -tzf "$carpeta_backup/$nombre_backup" | wc -l)
    
    # Tamaño del respaldo en formato legible
    tamano=$(du -h "$carpeta_backup/$nombre_backup" | cut -f1)
    
    estado="ÉXITO"
    codigo_salida=0
else
    cantidad_archivos=0
    tamano="0B"
    estado="ERROR"
    codigo_salida=1
fi

# 5. Registrar la operación en backup.log
{
    echo "----------------------------------------"
    echo "Fecha: $(date)"
    echo "Origen: $dir_origen"
    echo "Archivo generado: $carpeta_backup/$nombre_backup"
    echo "Cantidad de archivos: $cantidad_archivos"
    echo "Tamaño del respaldo: $tamano"
    echo "Estado del proceso: $estado"
    echo "----------------------------------------"
} >> "$archivo_log"

# 6. Mostrar resumen en pantalla
echo "Resumen del respaldo:"
echo "Fecha: $(date)"
echo "Archivos respaldados: $cantidad_archivos"
echo "Tamaño: $tamano"
echo "Estado: $estado"

exit $codigo_salida
