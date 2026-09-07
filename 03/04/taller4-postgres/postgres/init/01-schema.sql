CREATE SCHEMA IF NOT EXISTS academia;

-- 1. Tabla Profesores
CREATE TABLE IF NOT EXISTS academia.teachers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    department VARCHAR(80) NOT NULL
);

-- 2. Tabla Cursos (relacionada con Profesores)
CREATE TABLE IF NOT EXISTS academia.courses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    credits INTEGER NOT NULL CHECK (credits > 0),
    teacher_id INTEGER NOT NULL,
    CONSTRAINT fk_course_teacher 
        FOREIGN KEY (teacher_id) 
        REFERENCES academia.teachers (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
);

-- 3. Tabla Estudiantes
CREATE TABLE IF NOT EXISTS academia.students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL
);

-- 4. Tabla Matriculas (Relacion N:M con llaves foraneas)
CREATE TABLE IF NOT EXISTS academia.enrollments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    grade NUMERIC(3,2) CHECK (grade >= 0.0 AND grade <= 5.0),
    CONSTRAINT fk_enrollment_student 
        FOREIGN KEY (student_id) 
        REFERENCES academia.students (id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_enrollment_course 
        FOREIGN KEY (course_id) 
        REFERENCES academia.courses (id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT uq_student_course 
        UNIQUE (student_id, course_id)
);