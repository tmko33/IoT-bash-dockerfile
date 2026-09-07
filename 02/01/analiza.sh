#!/bin/bash

# 1. Validación: Comprobar que se haya proporcionado al menos un argumento ($#)
if [ "$#" -eq 0 ]; then
    echo "Error: No se especificaron archivos para analizar."
    echo "Uso correcto: $0 <archivo1.log> [archivo2.log ...]"
    exit 1
fi

TOTAL_ARCHIVOS=$#
PROCESADOS=0

echo "=========================================================="
echo "          INICIANDO PROCESAMIENTO DE REGISTROS            "
echo "=========================================================="

# Iterar sobre todos los argumentos pasados ($@)
for ARCHIVO in "$@"; do
    echo -e "\n--- Analizando: ${ARCHIVO} ---"
    
    # 2. Validación: Verificar existencia y permisos de lectura del archivo
    if [ ! -f "$ARCHIVO" ]; then
        echo "Error: El archivo '${ARCHIVO}' no existe o no es un archivo regular." >&2
        continue
    fi
    
    if [ ! -r "$ARCHIVO" ]; then
        echo "Error: Sin permisos de lectura sobre '${ARCHIVO}'." >&2
        continue
    fi

    # 3. Extracción de métricas
    LINEAS=$(wc -l < "$ARCHIVO")
    PALABRAS=$(wc -w < "$ARCHIVO")
    CARACTERES=$(wc -m < "$ARCHIVO")
    ERRORES=$(grep -c 'ERROR' "$ARCHIVO")
    WARNS=$(grep -c 'WARN' "$ARCHIVO")

    # 4. Formateo de salida
    echo "Total de líneas      : $LINEAS"
    echo "Total de palabras    : $PALABRAS"
    echo "Total de caracteres  : $CARACTERES"
    echo "Eventos ERROR        : $ERRORES"
    echo "Eventos WARN         : $WARNS"

    ((PROCESADOS++))
done

echo -e "\n=========================================================="
echo "Resumen final: ${PROCESADOS} de ${TOTAL_ARCHIVOS} archivos analizados correctamente."
echo "=========================================================="

exit 0
