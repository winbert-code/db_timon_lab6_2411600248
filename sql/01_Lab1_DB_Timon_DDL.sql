-- =============================================================
-- LABORATORY EXERCISE 1 - DATABASE CREATION & FOUNDATIONAL DDL
-- Database: DB_Timon
-- Run this script FIRST in dbGate.
-- =============================================================

CREATE DATABASE IF NOT EXISTS DB_Timon
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE DB_Timon;

-- Reset children before parents so the script can be re-run even after
-- Labs 2 and 3 have added their tables and foreign keys.
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS instructors;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;

-- -------------------------------------------------------------
-- Students
-- -------------------------------------------------------------
CREATE TABLE students (
    student_id     INT           NOT NULL AUTO_INCREMENT,
    first_name     VARCHAR(100)  NOT NULL,
    last_name      VARCHAR(100)  NOT NULL,
    date_of_birth  DATE          NOT NULL,
    email          VARCHAR(255)  NOT NULL UNIQUE,
    PRIMARY KEY (student_id)
) ENGINE = InnoDB;

-- -------------------------------------------------------------
-- Courses
-- -------------------------------------------------------------
CREATE TABLE courses (
    course_id    INT          NOT NULL AUTO_INCREMENT,
    course_code  VARCHAR(50)  NOT NULL UNIQUE,
    course_name  VARCHAR(255) NOT NULL,
    PRIMARY KEY (course_id)
) ENGINE = InnoDB;

-- -------------------------------------------------------------
-- Sample data (optional, useful for screenshots and testing)
-- -------------------------------------------------------------
INSERT INTO students (first_name, last_name, date_of_birth, email) VALUES
    ('Juan',   'Dela Cruz', '2003-05-14', 'juan.delacruz@example.com'),
    ('Maria',  'Santos',    '2004-01-22', 'maria.santos@example.com');

INSERT INTO courses (course_code, course_name) VALUES
    ('CS101', 'Introduction to Programming'),
    ('CS201', 'Database Systems');

-- Quick verification
SELECT student_id, first_name, last_name, date_of_birth, email FROM students;
SELECT course_id, course_code, course_name FROM courses;
