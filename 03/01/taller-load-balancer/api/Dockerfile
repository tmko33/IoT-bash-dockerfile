FROM python:3.12-slim

WORKDIR /app

# Aprovechamiento del sistema de capas de Docker para caché de dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]