import os
from datetime import datetime

import boto3
import psycopg2
from flask import Flask, jsonify, request
from psycopg2 import errors
from psycopg2.extras import RealDictCursor

app = Flask(__name__)

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "db"),
    "port": os.getenv("DB_PORT", "5432"),
    "dbname": os.getenv("DB_NAME", "equipment"),
    "user": os.getenv("DB_USER", "equipment"),
    "password": os.getenv("DB_PASSWORD", "change-me"),
}

S3_BUCKET = os.getenv("S3_BUCKET", "")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")


def get_db():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)


def get_s3():
    return boto3.client("s3", region_name=AWS_REGION)


@app.errorhandler(errors.UniqueViolation)
def handle_unique_violation(error):
    return jsonify({
        "error": "conflicto",
        "detail": "Ya existe un registro con esos datos únicos"
    }), 409


@app.errorhandler(psycopg2.Error)
def handle_db_error(error):
    return jsonify({
        "error": "database_error",
        "detail": str(error)
    }), 500


@app.get("/")
def root():
    return jsonify({
        "service": "equipment-api",
        "endpoints": [
            "/health",
            "/empleados",
            "/equipos",
            "/equipos/<id>/asignar",
            "/equipos/<id>/mantenimientos",
            "/equipos/<id>/historial",
            "/equipos/<id>/documentos"
        ]
    })


@app.get("/health")
def health():
    return jsonify({
        "status": "ok",
        "service": "equipment-api"
    })


# ---------------------------------------------------------------------------
# Empleados
# ---------------------------------------------------------------------------

@app.get("/empleados")
def list_employees():
    with get_db() as conn, conn.cursor() as cur:
        cur.execute("""
            SELECT id,
                   name AS nombre,
                   email AS correo,
                   department AS departamento
            FROM employees
            ORDER BY id
        """)
        return jsonify(cur.fetchall())


@app.post("/empleados")
def create_employee():
    data = request.get_json(force=True, silent=True) or {}
    if not data.get("nombre") or not data.get("correo"):
        return jsonify({"error": "nombre y correo son obligatorios"}), 400

    with get_db() as conn, conn.cursor() as cur:
        cur.execute("""
            INSERT INTO employees (name, email, department)
            VALUES (%s, %s, %s)
            RETURNING id,
                      name AS nombre,
                      email AS correo,
                      department AS departamento
        """, (
            data["nombre"],
            data["correo"],
            data.get("departamento")
        ))
        row = cur.fetchone()
        conn.commit()
        return jsonify(row), 201


@app.get("/empleados/<int:employee_id>")
def get_employee(employee_id):
    with get_db() as conn, conn.cursor() as cur:
        cur.execute("""
            SELECT id,
                   name AS nombre,
                   email AS correo,
                   department AS departamento
            FROM employees
            WHERE id = %s
        """, (employee_id,))
        row = cur.fetchone()
        if not row:
            return jsonify({"error": "empleado no encontrado"}), 404
        return jsonify(row)


# ---------------------------------------------------------------------------
# Equipos
# ---------------------------------------------------------------------------

EQUIPMENT_SELECT = """
    SELECT e.id,
           e.internal_code AS codigo_interno,
           e.type AS tipo,
           e.brand AS marca,
           e.model AS modelo,
           e.serial_number AS numero_serie,
           e.status AS estado,
           to_char(e.acquisition_date, 'YYYY-MM-DD') AS fecha_adquisicion,
           e.employee_id AS empleado_id,
           emp.name AS empleado_nombre
    FROM equipment e
    LEFT JOIN employees emp ON emp.id = e.employee_id
"""


@app.get("/equipos")
def list_equipment():
    with get_db() as conn, conn.cursor() as cur:
        cur.execute(EQUIPMENT_SELECT + " ORDER BY e.id")
        return jsonify(cur.fetchall())


@app.post("/equipos")
def create_equipment():
    data = request.get_json(force=True, silent=True) or {}
    if not data.get("codigo_interno") or not data.get("tipo"):
        return jsonify({"error": "codigo_interno y tipo son obligatorios"}), 400

    with get_db() as conn, conn.cursor() as cur:
        cur.execute("""
            INSERT INTO equipment (
                internal_code, type, brand, model, serial_number,
                status, acquisition_date, employee_id
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            data["codigo_interno"],
            data["tipo"],
            data.get("marca"),
            data.get("modelo"),
            data.get("numero_serie"),
            data.get("estado", "DISPONIBLE"),
            data.get("fecha_adquisicion"),
            data.get("empleado_id")
        ))
        new_id = cur.fetchone()["id"]
        cur.execute(EQUIPMENT_SELECT + " WHERE e.id = %s", (new_id,))
        row = cur.fetchone()
        conn.commit()
        return jsonify(row), 201


@app.get("/equipos/<int:equipment_id>")
def get_equipment(equipment_id):
    with get_db() as conn, conn.cursor() as cur:
        cur.execute(EQUIPMENT_SELECT + " WHERE e.id = %s", (equipment_id,))
        row = cur.fetchone()
        if not row:
            return jsonify({"error": "equipo no encontrado"}), 404
        return jsonify(row)


@app.put("/equipos/<int:equipment_id>")
def update_equipment(equipment_id):
    data = request.get_json(force=True, silent=True) or {}

    with get_db() as conn, conn.cursor() as cur:
        cur.execute("""
            UPDATE equipment
            SET internal_code = COALESCE(%s, internal_code),
                type = COALESCE(%s, type),
                brand = COALESCE(%s, brand),
                model = COALESCE(%s, model),
                serial_number = COALESCE(%s, serial_number),
                status = COALESCE(%s, status),
                acquisition_date = COALESCE(%s, acquisition_date),
                employee_id = COALESCE(%s, employee_id)
            WHERE id = %s
            RETURNING id
        """, (
            data.get("codigo_interno"),
            data.get("tipo"),
            data.get("marca"),
            data.get("modelo"),
            data.get("numero_serie"),
            data.get("estado"),
            data.get("fecha_adquisicion"),
            data.get("empleado_id"),
            equipment_id
        ))
        row = cur.fetchone()
        if not row:
            return jsonify({"error": "equipo no encontrado"}), 404

        cur.execute(EQUIPMENT_SELECT + " WHERE e.id = %s", (equipment_id,))
        updated = cur.fetchone()
        conn.commit()
        return jsonify(updated)


@app.post("/equipos/<int:equipment_id>/asignar")
def assign_equipment(equipment_id):
    data = request.get_json(force=True, silent=True) or {}
    employee_id = data.get("empleado_id")
    if not employee_id:
        return jsonify({"error": "empleado_id es obligatorio"}), 400

    with get_db() as conn, conn.cursor() as cur:
        cur.execute("""
            SELECT id, status, internal_code
            FROM equipment
            WHERE id = %s
        """, (equipment_id,))
        equipment = cur.fetchone()
        if not equipment:
            return jsonify({"error": "equipo no encontrado"}), 404

        cur.execute("SELECT id, name FROM employees WHERE id = %s", (employee_id,))
        employee = cur.fetchone()
        if not employee:
            return jsonify({"error": "empleado no encontrado"}), 404

        if equipment["status"] != "DISPONIBLE":
            return jsonify({
                "error": "equipo no disponible",
                "estado": equipment["status"]
            }), 409

        cur.execute("""
            UPDATE equipment
            SET employee_id = %s, status = 'ASIGNADO'
            WHERE id = %s
        """, (employee_id, equipment_id))

        cur.execute("""
            INSERT INTO assignments (equipment_id, employee_id)
            VALUES (%s, %s)
        """, (equipment_id, employee_id))

        conn.commit()
        return jsonify({
            "message": "equipo asignado",
            "equipo": equipment["internal_code"],
            "empleado": employee["name"]
        })


@app.post("/equipos/<int:equipment_id>/mantenimientos")
def create_maintenance(equipment_id):
    data = request.get_json(force=True, silent=True) or {}

    if not data.get("tipo"):
        return jsonify({"error": "tipo es obligatorio"}), 400

    cost = data.get("costo")
    if cost is not None:
        try:
            cost = float(cost)
        except (TypeError, ValueError):
            return jsonify({"error": "costo debe ser numérico"}), 400

    with get_db() as conn, conn.cursor() as cur:
        cur.execute("SELECT id, internal_code FROM equipment WHERE id = %s", (equipment_id,))
        equipment = cur.fetchone()
        if not equipment:
            return jsonify({"error": "equipo no encontrado"}), 404

        cur.execute("""
            INSERT INTO maintenance (equipment_id, type, description, cost)
            VALUES (%s, %s, %s, %s)
            RETURNING id,
                      to_char(maintenance_date, 'YYYY-MM-DD HH24:MI:SS') AS fecha,
                      type AS tipo,
                      description AS descripcion,
                      cost::float AS costo
        """, (
            equipment_id,
            data.get("tipo"),
            data.get("descripcion"),
            cost
        ))
        row = cur.fetchone()
        conn.commit()
        return jsonify(row), 201


@app.get("/equipos/<int:equipment_id>/historial")
def get_history(equipment_id):
    with get_db() as conn, conn.cursor() as cur:
        cur.execute("SELECT id, internal_code FROM equipment WHERE id = %s", (equipment_id,))
        equipment = cur.fetchone()
        if not equipment:
            return jsonify({"error": "equipo no encontrado"}), 404

        cur.execute("""
            SELECT to_char(a.assigned_at, 'YYYY-MM-DD') AS fecha,
                   'Asignación' AS evento,
                   emp.name AS detalle
            FROM assignments a
            JOIN employees emp ON emp.id = a.employee_id
            WHERE a.equipment_id = %s

            UNION ALL

            SELECT to_char(m.maintenance_date, 'YYYY-MM-DD') AS fecha,
                   'Mantenimiento' AS evento,
                   COALESCE(m.type, 'Mantenimiento') AS detalle
            FROM maintenance m
            WHERE m.equipment_id = %s

            ORDER BY fecha
        """, (equipment_id, equipment_id))

        return jsonify({
            "equipo": equipment["internal_code"],
            "historial": cur.fetchall()
        })


# ---------------------------------------------------------------------------
# Documentos (S3)
# ---------------------------------------------------------------------------

@app.post("/equipos/<int:equipment_id>/documentos")
def upload_document(equipment_id):
    if "file" not in request.files:
        return jsonify({"error": "file es obligatorio"}), 400

    file = request.files["file"]
    safe_name = os.path.basename(file.filename or "")
    if not safe_name:
        return jsonify({"error": "nombre de archivo vacío"}), 400

    if not S3_BUCKET:
        return jsonify({"error": "S3_BUCKET no configurado"}), 500

    with get_db() as conn, conn.cursor() as cur:
        cur.execute("SELECT id, internal_code FROM equipment WHERE id = %s", (equipment_id,))
        equipment = cur.fetchone()
        if not equipment:
            return jsonify({"error": "equipo no encontrado"}), 404

        s3_key = f"equipos/{equipment['internal_code']}/{safe_name}"

        try:
            get_s3().upload_fileobj(file, S3_BUCKET, s3_key)
        except Exception as error:
            return jsonify({
                "error": "s3_upload_failed",
                "detail": str(error)
            }), 502

        cur.execute("""
            INSERT INTO documents (equipment_id, file_name, s3_key)
            VALUES (%s, %s, %s)
            RETURNING id,
                      file_name,
                      s3_key,
                      to_char(created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at
        """, (equipment_id, safe_name, s3_key))
        row = cur.fetchone()
        conn.commit()
        return jsonify(row), 201


@app.get("/equipos/<int:equipment_id>/documentos")
def list_documents(equipment_id):
    with get_db() as conn, conn.cursor() as cur:
        cur.execute("SELECT id FROM equipment WHERE id = %s", (equipment_id,))
        if not cur.fetchone():
            return jsonify({"error": "equipo no encontrado"}), 404

        cur.execute("""
            SELECT id,
                   file_name,
                   s3_key,
                   to_char(created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at
            FROM documents
            WHERE equipment_id = %s
            ORDER BY id
        """, (equipment_id,))
        return jsonify(cur.fetchall())


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
