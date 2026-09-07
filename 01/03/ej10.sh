#!/bin/bash

# 1. Obtener la fecha actual para el nombre de la carpeta (Formato: AAAA-MM-DD)
fecha_actual=$(date +"%F")
nombre_carpeta="backup_$fecha_actual"

# 2. Crear la carpeta
# Se usa -p para evitar error si ya existe, aunque el script suele correr una vez al día
if mkdir "$nombre_carpeta"; then
    echo "Carpeta '$nombre_carpeta' creada exitosamente."
else
    echo "Error: No se pudo crear la carpeta '$nombre_carpeta'."
    exit 1
fi

# 3. Copiar todos los archivos .txt del directorio actual a la nueva carpeta
# Se usa shopt para manejar el caso donde no haya archivos .txt sin dar error de sintaxis
shopt -s nullglob
archivos_txt=(*.txt)
shopt -u nullglob

contador=0

if [ ${#archivos_txt[@]} -eq 0 ]; then
    echo "No se encontraron archivos .txt para copiar."
    mensaje="No se encontraron archivos .txt"
else
    for archivo in "${archivos_txt[@]}"; do
        if cp "$archivo" "$nombre_carpeta/"; then
            ((contador++))
        else
            echo "Advertencia: No se pudo copiar '$archivo'."
        fi
    done
    mensaje="Se copiaron $contador archivos .txt exitosamente."
fi

# 4. Generar el archivo reporte.log dentro de la carpeta creada
{
    echo "Reporte de Backup"
    echo "================="
    echo "Fecha: $(date)"
    echo "Carpeta de destino: $nombre_carpeta"
    echo "Estado: $mensaje"
    echo "Cantidad de archivos copiados: $contador"
} > "$nombre_carpeta/reporte.log"

# 5. Mostrar mensaje de éxito o error según el código de salida
# Verificamos si la escritura del log y las copias críticas fueron bien
if [ $contador -gt 0 ] || [ ${#archivos_txt[@]} -eq 0 ]; then
    echo "ÉXITO: $mensaje"
    echo "El reporte se encuentra en: $nombre_carpeta/reporte.log"
    exit 0
else
    echo "ERROR: Falló la operación de copia."
    exit 1
fi   
