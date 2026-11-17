CREATE TABLE IF NOT EXISTS employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    department VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS equipment (
    id SERIAL PRIMARY KEY,
    internal_code VARCHAR(50) UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL,
    brand VARCHAR(80),
    model VARCHAR(80),
    serial_number VARCHAR(100) UNIQUE,
    status VARCHAR(30) NOT NULL DEFAULT 'DISPONIBLE',
    acquisition_date DATE,
    employee_id INTEGER REFERENCES employees(id)
);

CREATE TABLE IF NOT EXISTS assignments (
    id SERIAL PRIMARY KEY,
    equipment_id INTEGER NOT NULL REFERENCES equipment(id),
    employee_id INTEGER NOT NULL REFERENCES employees(id),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    returned_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS maintenance (
    id SERIAL PRIMARY KEY,
    equipment_id INTEGER NOT NULL REFERENCES equipment(id),
    maintenance_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    type VARCHAR(50),
    description TEXT,
    cost NUMERIC(12,2)
);

CREATE TABLE IF NOT EXISTS documents (
    id SERIAL PRIMARY KEY,
    equipment_id INTEGER NOT NULL REFERENCES equipment(id),
    file_name VARCHAR(255) NOT NULL,
    s3_key VARCHAR(500) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_equipment_employee ON equipment(employee_id);
CREATE INDEX IF NOT EXISTS idx_assignments_equipment ON assignments(equipment_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_equipment ON maintenance(equipment_id);
CREATE INDEX IF NOT EXISTS idx_documents_equipment ON documents(equipment_id);

INSERT INTO employees (name, email, department)
VALUES
    ('Ana Torres', 'ana@empresa.com', 'Tecnología'),
    ('Carlos Gómez', 'carlos@empresa.com', 'Finanzas')
ON CONFLICT (email) DO NOTHING;

INSERT INTO equipment (
    internal_code, type, brand, model, serial_number,
    status, acquisition_date
)
VALUES (
    'LAP-0010', 'Laptop', 'Lenovo', 'ThinkPad E14', 'ABC123456',
    'DISPONIBLE', '2026-01-15'
)
ON CONFLICT (internal_code) DO NOTHING;
