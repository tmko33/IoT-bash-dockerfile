import os
import psycopg
from psycopg.rows import dict_row
from flask import Flask, jsonify, request

app = Flask(__name__)

INSTANCE = os.getenv("INSTANCE", "api-local")
DB_HOST = os.getenv("DB_HOST", "db")
DB_NAME = os.getenv("DB_NAME", "shop")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

def get_connection():
    return psycopg.connect(
        host=DB_HOST,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        row_factory=dict_row
    )

@app.get("/products")
def get_products():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, price::float FROM products ORDER BY id ASC;")
            products = cur.fetchall()
            return jsonify({
                "served_by": INSTANCE,
                "products": products
            }), 200

@app.get("/products/<int:product_id>")
def get_product(product_id):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, price::float FROM products WHERE id = %s;", (product_id,))
            product = cur.fetchone()
            if not product:
                return jsonify({"served_by": INSTANCE, "error": "Product not found"}), 404
            return jsonify({
                "served_by": INSTANCE,
                "product": product
            }), 200

@app.post("/products")
def create_product():
    data = request.get_json()
    if not data or "name" not in data or "price" not in data:
        return jsonify({"served_by": INSTANCE, "error": "Campos 'name' y 'price' requeridos"}), 400

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO products (name, price) VALUES (%s, %s) RETURNING id, name, price::float;",
                (data["name"], data["price"])
            )
            new_prod = cur.fetchone()
            conn.commit()
            return jsonify({
                "served_by": INSTANCE,
                "product": new_prod
            }), 201

@app.put("/products/<int:product_id>")
def update_product(product_id):
    data = request.get_json()
    if not data or "name" not in data or "price" not in data:
        return jsonify({"served_by": INSTANCE, "error": "Campos 'name' y 'price' requeridos"}), 400

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE products SET name = %s, price = %s WHERE id = %s RETURNING id, name, price::float;",
                (data["name"], data["price"], product_id)
            )
            updated_prod = cur.fetchone()
            if not updated_prod:
                return jsonify({"served_by": INSTANCE, "error": "Product not found"}), 404
            conn.commit()
            return jsonify({
                "served_by": INSTANCE,
                "product": updated_prod
            }), 200

@app.delete("/products/<int:product_id>")
def delete_product(product_id):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM products WHERE id = %s RETURNING id;", (product_id,))
            deleted_prod = cur.fetchone()
            if not deleted_prod:
                return jsonify({"served_by": INSTANCE, "error": "Product not found"}), 404
            conn.commit()
            return jsonify({
                "served_by": INSTANCE,
                "message": f"Producto con ID {product_id} eliminado exitosamente"
            }), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)