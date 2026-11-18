# 05/01 — Sistema de seguimiento de equipos

Proyecto de la clase 05_cloud. La aplicación permite registrar empleados,
equipos, asignaciones, mantenimientos y documentos; los documentos se guardan
en S3 y los metadatos en PostgreSQL.

## Arquitectura objetivo

```text
Internet
   |
   v
EC2 (Docker Compose)
   |
   +--> Nginx :80
   |      |
   |      v
   |   Flask :5000
   |      |
   |      +--> PostgreSQL
   |      |
   |      +--> S3
   |
   +--> Amazon ECR (imagen de Flask)
```

La imagen de la API se construye **una vez** en el computador local, se publica
en ECR y la EC2 solo hace `docker pull`. En EC2 no se construye la imagen.

## Estructura

```text
05/01/
├── api/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── db/
│   └── init.sql
├── nginx/
│   └── nginx.conf
├── docker-compose.yml
├── .env.example
├── .gitignore
├── capturas/
├── pruebas.txt
└── preguntas.txt
```

## Fase A — Probar localmente

Requisitos: Docker Desktop encendido y el puerto 8080 libre.

```powershell
cd C:\Users\phano\Documents\9no\IoT\IoT-bash-dockerfile\05\01
docker compose up -d --build
docker compose ps
```

Espera a que `equipment-db` esté `healthy`, `equipment-api` esté `healthy` y
`equipment-nginx` esté arriba.

Prueba la API a través de Nginx:

```powershell
curl.exe http://localhost:8080/health
```

Respuesta esperada:

```json
{"service":"equipment-api","status":"ok"}
```

Lista los empleados de ejemplo:

```powershell
curl.exe http://localhost:8080/empleados
```

Debe devolver Ana Torres y Carlos Gómez.

Lista los equipos:

```powershell
curl.exe http://localhost:8080/equipos
```

Debe devolver el equipo `LAP-0010`.

> **Importante en PowerShell:** `curl.exe -d '{"clave":"valor"}'` puede perder
> las comillas internas y enviar JSON inválido. Para los POST usa
> `Invoke-RestMethod` con hashtables (recomendado) o
> `curl.exe --data-binary "@archivo.json"`.

Crea un empleado:

```powershell
$body = @{
    nombre = "Laura Díaz"
    correo = "laura@empresa.com"
    departamento = "Operaciones"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/empleados" -Method Post -ContentType "application/json" -Body $body | ConvertTo-Json -Depth 5
```

Crea un equipo:

```powershell
$body = @{
    codigo_interno = "LAP-0011"
    tipo = "Laptop"
    marca = "Dell"
    modelo = "Latitude 5440"
    numero_serie = "XYZ987654"
    estado = "DISPONIBLE"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/equipos" -Method Post -ContentType "application/json" -Body $body | ConvertTo-Json -Depth 5
```

Asigna el equipo 2 al empleado 3:

```powershell
$body = @{ empleado_id = 3 } | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/equipos/2/asignar" -Method Post -ContentType "application/json" -Body $body | ConvertTo-Json -Depth 5
```

Registra un mantenimiento:

```powershell
$body = @{
    tipo = "Preventivo"
    descripcion = "Limpieza y actualización"
    costo = 120000
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/equipos/1/mantenimientos" -Method Post -ContentType "application/json" -Body $body | ConvertTo-Json -Depth 5
```

Consulta el historial:

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/equipos/1/historial" | ConvertTo-Json -Depth 5
```

Respuesta esperada, aproximada:

```json
{
  "equipo": "LAP-0010",
  "historial": [
    {"fecha": "2026-11-17", "evento": "Mantenimiento", "detalle": "Preventivo"}
  ]
}
```

Comprueba PostgreSQL:

```powershell
docker exec -it equipment-db psql -U equipment -d equipment -c "\dt"
docker exec -it equipment-db psql -U equipment -d equipment -c "SELECT * FROM employees;"
docker exec -it equipment-db psql -U equipment -d equipment -c "SELECT * FROM equipment;"
```

Detén el stack sin borrar la base:

```powershell
docker compose down
```

Si quieres borrar también el volumen de PostgreSQL:

```powershell
docker compose down -v
```

> La carga de documentos a S3 se prueba en la Fase C, cuando exista el bucket
> y credenciales de AWS. En local, sin `S3_BUCKET` y sin credenciales, el
> endpoint `/equipos/<id>/documentos` devuelve un error controlado.

## Fase B — ECR

1. Configurar AWS CLI con las credenciales temporales de Learner Lab.
2. Crear el repositorio `equipment-api`.
3. Autenticar Docker contra ECR.
4. Construir la imagen para `linux/amd64`.
5. Etiquetar y hacer `docker push`.

Comandos de referencia (se ajustarán con el Account ID real):

```powershell
aws sts get-caller-identity
aws ecr create-repository --repository-name equipment-api --image-scanning-configuration scanOnPush=true --region us-east-1
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
docker buildx build --platform linux/amd64 --provenance=false -t equipment-api:1.0 ./api --load
docker tag equipment-api:1.0 <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/equipment-api:1.0
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/equipment-api:1.0
```

## Fase C — S3

1. Crear un bucket privado `equipment-documents-<sufijo-único>`.
2. Bloquear el acceso público.
3. En la EC2, usar el rol `LabRole` para que boto3 suba archivos sin claves
   hardcodeadas.
4. Probar `POST /equipos/<id>/documentos` con un archivo pequeño.

## Fase D — EC2

1. Crear `equipment-server` con Ubuntu 24.04, `t3.micro`, key pair
   `curso-ec2-key`, Security Group con 22 (IP administrativa) y 80 (HTTP), e
   IAM instance profile `LabRole`.
2. Instalar Docker y AWS CLI.
3. Autenticar Docker contra ECR y hacer `docker pull`.
4. Copiar `docker-compose.yml`, `nginx/` y `db/` a la EC2.
5. Cambiar el compose de `build:` a `image: <URI_ECR>:1.0` y publicar el 80.
6. Levantar con `docker compose up -d --pull always`.
7. Verificar `/health`, PostgreSQL y S3.

## Evidencias

- `capturas/01-local-health.png`
- `capturas/02-local-empleados.png`
- `capturas/03-local-equipos.png`
- `capturas/04-local-postgres.png`
- `capturas/05-ecr.png`
- `capturas/06-s3.png`
- `capturas/07-ec2.png`
- `capturas/08-compose.png`
- `capturas/09-api-publica.png`
- `pruebas.txt`
- `preguntas.txt`

## Notas de Learner Lab

- Las credenciales de AWS CLI son temporales; se copian desde **AWS Details**.
- No crear IAM roles: usar `LabRole` como instance profile.
- Terminar los recursos al final del laboratorio.
- No subir `.env`, credenciales ni archivos `.pem` al repositorio.
