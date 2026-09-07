FROM ubuntu:latest

# Instalación de herramientas de diagnóstico y procesamiento de texto
# Se limpia la caché de apt en la misma capa para optimizar el tamaño final
RUN apt-get update && apt-get install -y \
    bash \
    coreutils \
    grep \
    gawk \
    procps \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Directorio de trabajo
WORKDIR /app

# Copia del contexto local al directorio de trabajo dentro de la imagen
COPY . /app

# Comando por defecto al iniciar el contenedor
CMD ["bash"]