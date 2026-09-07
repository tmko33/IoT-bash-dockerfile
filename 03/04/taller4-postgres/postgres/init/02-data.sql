-- Inserción de Profesores
INSERT INTO academia.teachers (name, email, department) VALUES
('Dr. Roberto Martinez', 'roberto.martinez@javeriana.edu.co', 'Ingenieria de Sistemas'),
('Dra. Elena Vasquez', 'elena.vasquez@javeriana.edu.co', 'Ciencias de la Computacion');

-- Inserción de Cursos
INSERT INTO academia.courses (name, credits, teacher_id) VALUES
('Cloud Computing e IoT', 3, 1),
('Arquitectura de Software', 4, 1),
('Bases de Datos Avanzadas', 3, 2);

-- Inserción de Estudiantes
INSERT INTO academia.students (name, email) VALUES
('Phanor Castillo', 'phanor.castillo@javeriana.edu.co'),
('Ana Maria Diaz', 'ana.diaz@javeriana.edu.co'),
('Mateo Fernandez', 'mateo.fernandez@javeriana.edu.co'),
('Laura Sofia Rios', 'laura.rios@javeriana.edu.co');

-- Inserción de Matrículas
INSERT INTO academia.enrollments (student_id, course_id, grade) VALUES
(1, 1, 4.8), -- Phanor en Cloud Computing
(1, 2, 4.5), -- Phanor en Arquitectura
(2, 1, 4.2), -- Ana en Cloud Computing
(3, 3, 3.9), -- Mateo en Bases de Datos
(4, 2, 4.6); -- Laura en Arquitectura