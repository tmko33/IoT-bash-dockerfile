// Conmutar el contexto de ejecución a la base de datos 'tienda'
db = db.getSiblingDB('tienda');

// 1. Colección: products
db.products.insertMany([
  {
    _id: ObjectId("64b8a1c1a1b2c3d4e5f60001"),
    name: "Laptop ThinkPad T14",
    price: 4500000,
    stock: 7,
    category: "Computadores",
    specs: { ram: "32GB", cpu: "Ryzen 7 Pro", storage: "1TB NVMe" }
  },
  {
    _id: ObjectId("64b8a1c1a1b2c3d4e5f60002"),
    name: "Mouse Ergonomico MX Master 3S",
    price: 320000,
    stock: 18,
    category: "Accesorios",
    specs: { dpi: 8000, wireless: true }
  },
  {
    _id: ObjectId("64b8a1c1a1b2c3d4e5f60003"),
    name: "Teclado Mecanico Keychron K2",
    price: 380000,
    stock: 12,
    category: "Accesorios",
    specs: { switches: "Gateron Brown", layout: "75%" }
  },
  {
    _id: ObjectId("64b8a1c1a1b2c3d4e5f60004"),
    name: "Monitor Dell 27 4K",
    price: 1650000,
    stock: 4,
    category: "Monitores",
    specs: { resolution: "3840x2160", panel: "IPS" }
  }
]);

// 2. Colección: customers
db.customers.insertMany([
  {
    customerId: 1,
    name: "Phanor Castillo",
    email: "phanor.castillo@javeriana.edu.co",
    address: { city: "Cali", department: "Valle del Cauca" }
  },
  {
    customerId: 2,
    name: "Ana Maria Diaz",
    email: "ana.diaz@javeriana.edu.co",
    address: { city: "Tulua", department: "Valle del Cauca" }
  },
  {
    customerId: 3,
    name: "Carlos Gomez",
    email: "carlos.gomez@javeriana.edu.co",
    address: { city: "Bogota", department: "Cundinamarca" }
  }
]);

// 3. Colección: orders (Reto con items embebidos y referencias BSON)
db.orders.insertMany([
  {
    orderId: 101,
    customerId: 1,
    date: ISODate("2026-08-24T08:30:00Z"),
    status: "completed",
    items: [
      { product: "Laptop ThinkPad T14", unitPrice: 4500000, quantity: 1 },
      { product: "Mouse Ergonomico MX Master 3S", unitPrice: 320000, quantity: 1 }
    ],
    total: 4820000
  },
  {
    orderId: 102,
    customerId: 2,
    date: ISODate("2026-08-24T10:15:00Z"),
    status: "processing",
    items: [
      { product: "Teclado Mecanico Keychron K2", unitPrice: 380000, quantity: 2 }
    ],
    total: 760000
  },
  {
    orderId: 103,
    customerId: 1,
    date: ISODate("2026-08-25T14:00:00Z"),
    status: "completed",
    items: [
      { product: "Monitor Dell 27 4K", unitPrice: 1650000, quantity: 1 }
    ],
    total: 1650000
  }
]);

// Creación de índices para optimizar consultas frecuentes
db.customers.createIndex({ email: 1 }, { unique: true });
db.orders.createIndex({ customerId: 1 });