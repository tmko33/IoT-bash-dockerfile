CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2) NOT NULL
);

INSERT INTO products (name, price) VALUES
('Laptop ThinkPad T14', 4500000.00),
('Teclado Mecanico Inalambrico', 320000.00),
('Mouse Ergonomico Logitech', 280000.00),
('Monitor Dell 27 Pulgadas 4K', 1650000.00),
('Audifonos Sony WH-1000XM5', 1200000.00);