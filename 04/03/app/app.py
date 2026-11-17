import os
import socket
from datetime import datetime, timezone
from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def home():
    return jsonify({
        "message": "Hola desde EC2",
        "container_hostname": socket.gethostname(),
        "ec2_hostname": os.getenv("EC2_HOSTNAME", "desconocido"),
        "time": datetime.now(timezone.utc).isoformat()
    })


@app.get("/health")
def health():
    return {"status": "ok"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
