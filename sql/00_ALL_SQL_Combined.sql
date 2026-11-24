-- =============================================================
-- ALL SQL USED IN LABORATORY EXERCISES 1-5 (DB_Timon)
-- Combined in the order they are run.
-- Sections 07, 08 and 09 are the safe, re-runnable "if already exists" setup.
-- =============================================================

-- ############################################################
-- FILE: 01_Lab1_DB_Timon_DDL.sql
-- ############################################################

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


-- ############################################################
-- FILE: 02_Lab2_Relationships.sql
-- ############################################################

-- =============================================================
-- LABORATORY EXERCISE 2 - ADVANCED TABLE DESIGN & RELATIONSHIPS
-- Database: DB_Timon
-- Requires: 01_Lab1_DB_Timon_DDL.sql to have been run first.
-- =============================================================

USE DB_Timon;

-- -------------------------------------------------------------
-- 0. Make this script re-runnable: remove the objects added by a
--    previous run of Lab 2, keeping the Lab 1 courses data.
-- -------------------------------------------------------------
DROP TABLE IF EXISTS enrollments;

SET @dropFk = IF(
    (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA = DATABASE()
       AND TABLE_NAME = 'courses'
       AND CONSTRAINT_NAME = 'fk_courses_instructor') > 0,
    'ALTER TABLE courses DROP FOREIGN KEY fk_courses_instructor',
    'SELECT 1');
PREPARE stmt FROM @dropFk;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @dropCol = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'courses'
       AND COLUMN_NAME = 'instructor_id') > 0,
    'ALTER TABLE courses DROP COLUMN instructor_id',
    'SELECT 1');
PREPARE stmt FROM @dropCol;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DROP TABLE IF EXISTS instructors;

-- -------------------------------------------------------------
-- 1. Instructors table (1:M with Courses)
-- -------------------------------------------------------------
CREATE TABLE instructors (
    instructor_id  INT          NOT NULL AUTO_INCREMENT,
    first_name     VARCHAR(100) NOT NULL,
    last_name      VARCHAR(100) NOT NULL,
    department     VARCHAR(100) NULL,
    PRIMARY KEY (instructor_id)
) ENGINE = InnoDB;

-- -------------------------------------------------------------
-- 2. Alter Courses: add instructor_id + FOREIGN KEY
--    One Instructor teaches many Courses.
--    instructor_id is nullable while a course is unassigned.
-- -------------------------------------------------------------
ALTER TABLE courses
    ADD COLUMN instructor_id INT NULL AFTER course_name,
    ADD CONSTRAINT fk_courses_instructor
        FOREIGN KEY (instructor_id)
        REFERENCES instructors (instructor_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE;

-- -------------------------------------------------------------
-- 3. Enrollments junction table (resolves M:N Students <-> Courses)
-- -------------------------------------------------------------
CREATE TABLE enrollments (
    enrollment_id    INT      NOT NULL AUTO_INCREMENT,
    student_id       INT      NOT NULL,
    course_id        INT      NOT NULL,
    enrollment_date  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (enrollment_id),
    CONSTRAINT uq_enrollment UNIQUE (student_id, course_id),
    CONSTRAINT fk_enrollments_student
        FOREIGN KEY (student_id) REFERENCES students (student_id),
    CONSTRAINT fk_enrollments_course
        FOREIGN KEY (course_id) REFERENCES courses (course_id)
) ENGINE = InnoDB;

-- -------------------------------------------------------------
-- Sample data for the relationships
-- -------------------------------------------------------------
INSERT INTO instructors (first_name, last_name, department) VALUES
    ('Alan',  'Turing', 'Computer Science'),
    ('Grace', 'Hopper', 'Computer Science');

UPDATE courses SET instructor_id = 1 WHERE course_code = 'CS101';
UPDATE courses SET instructor_id = 2 WHERE course_code = 'CS201';

INSERT INTO enrollments (student_id, course_id) VALUES
    (1, 1),
    (1, 2),
    (2, 1);

-- Quick verification: relationship report
SELECT s.first_name AS student,
       s.last_name  AS student_last,
       c.course_code,
       c.course_name,
       i.first_name AS instructor,
       e.enrollment_date
FROM   enrollments e
JOIN   students    s ON s.student_id    = e.student_id
JOIN   courses     c ON c.course_id     = e.course_id
LEFT JOIN instructors i ON i.instructor_id = c.instructor_id
ORDER  BY s.student_id, c.course_id;


-- ############################################################
-- FILE: 03_Lab3_Users_Roles_Auth.sql
-- ############################################################

-- =============================================================
-- LABORATORY EXERCISE 3 - ADVANCED TABLE DESIGN, RELATIONSHIPS
--                          & USER MANAGEMENT
-- Database: DB_Timon
-- Standalone script: rebuilds the FINAL schema from scratch.
-- Run this after Labs 1 and 2 (or by itself).
-- =============================================================

USE DB_Timon;

-- Drop in child-to-parent order so the script is re-runnable.
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS instructors;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;

-- -------------------------------------------------------------
-- 1. Roles and Users (authentication + authorization)
-- -------------------------------------------------------------
CREATE TABLE roles (
    role_id    INT          NOT NULL AUTO_INCREMENT,
    role_name  VARCHAR(50)  NOT NULL UNIQUE,
    PRIMARY KEY (role_id)
) ENGINE = InnoDB;

CREATE TABLE users (
    user_id       INT          NOT NULL AUTO_INCREMENT,
    username      VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id       INT          NOT NULL,
    PRIMARY KEY (user_id),
    CONSTRAINT fk_users_role
        FOREIGN KEY (role_id) REFERENCES roles (role_id)
) ENGINE = InnoDB;

-- -------------------------------------------------------------
-- 2. Instructors and Students (1:1 with Users via UNIQUE user_id)
-- -------------------------------------------------------------
CREATE TABLE instructors (
    instructor_id  INT          NOT NULL AUTO_INCREMENT,
    user_id        INT          NOT NULL UNIQUE,
    first_name     VARCHAR(100) NOT NULL,
    last_name      VARCHAR(100) NOT NULL,
    department     VARCHAR(100) NULL,
    PRIMARY KEY (instructor_id),
    CONSTRAINT fk_instructors_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE = InnoDB;

CREATE TABLE students (
    student_id     INT          NOT NULL AUTO_INCREMENT,
    user_id        INT          NOT NULL UNIQUE,
    first_name     VARCHAR(100) NOT NULL,
    last_name      VARCHAR(100) NOT NULL,
    date_of_birth  DATE         NULL,
    PRIMARY KEY (student_id),
    CONSTRAINT fk_students_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE = InnoDB;

-- -------------------------------------------------------------
-- 3. Courses (1:M from Instructors)
-- -------------------------------------------------------------
CREATE TABLE courses (
    course_id     INT          NOT NULL AUTO_INCREMENT,
    course_code   VARCHAR(50)  NOT NULL UNIQUE,
    course_name   VARCHAR(255) NOT NULL,
    instructor_id INT          NULL,
    PRIMARY KEY (course_id),
    CONSTRAINT fk_courses_instructor
        FOREIGN KEY (instructor_id) REFERENCES instructors (instructor_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -------------------------------------------------------------
-- 4. Enrollments (M:N junction, 1:M from both sides)
-- -------------------------------------------------------------
CREATE TABLE enrollments (
    enrollment_id   INT      NOT NULL AUTO_INCREMENT,
    student_id      INT      NOT NULL,
    course_id       INT      NOT NULL,
    enrollment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (enrollment_id),
    CONSTRAINT unique_enrollment UNIQUE (student_id, course_id),
    CONSTRAINT fk_enrollments_student
        FOREIGN KEY (student_id) REFERENCES students (student_id),
    CONSTRAINT fk_enrollments_course
        FOREIGN KEY (course_id) REFERENCES courses (course_id)
) ENGINE = InnoDB;

-- -------------------------------------------------------------
-- 5. Seed roles
-- -------------------------------------------------------------
INSERT INTO roles (role_id, role_name) VALUES
    (1, 'Admin'),
    (2, 'Teacher'),
    (3, 'Student');

-- -------------------------------------------------------------
-- 6. Seed demo login accounts
--    Passwords are PBKDF2-HMAC-SHA256 (100,000 iterations, 16-byte
--    random salt, 32-byte hash) in the format used by the VB app:
--    pbkdf2_sha256$100000$<base64 salt>$<base64 hash>
--    admin / Admin@123
--    teacher1 / Teacher@123
--    student1 / Student@123
-- -------------------------------------------------------------
INSERT INTO users (username, password_hash, role_id) VALUES
    ('admin',    'pbkdf2_sha256$100000$YsTsBdEifNDP+dlL5TPp5A==$/7gsFUtdJyc2jOAP8yPtIDkBFXJ8t2F9GkVlEqtT/Eg=', 1),
    ('teacher1', 'pbkdf2_sha256$100000$tLOviNFFzugAUF3eXpbgaw==$4k0nn0fTYHzfSnIBg7EeNHHzhGtBZ62pHmcJqGAig/Y=', 2),
    ('student1', 'pbkdf2_sha256$100000$QdDT5d7/dC8bLCyGX89TXQ==$y09RkfXh5X9P49viWzjgkbO1gURKStt0qQYWXe+htHc=', 3);

-- -------------------------------------------------------------
-- 7. Seed matching profiles and sample academic data
-- -------------------------------------------------------------
INSERT INTO instructors (user_id, first_name, last_name, department)
SELECT user_id, 'Alan', 'Turing', 'Computer Science'
FROM   users WHERE username = 'teacher1';

INSERT INTO students (user_id, first_name, last_name, date_of_birth)
SELECT user_id, 'Juan', 'Dela Cruz', '2003-05-14'
FROM   users WHERE username = 'student1';

INSERT INTO courses (course_code, course_name, instructor_id)
VALUES
    ('CS101', 'Introduction to Programming', 1),
    ('CS201', 'Database Systems',             1);

INSERT INTO enrollments (student_id, course_id)
VALUES (1, 1), (1, 2);

-- Quick verification
SELECT u.user_id, u.username, r.role_name, u.password_hash
FROM   users u JOIN roles r ON r.role_id = u.role_id;

SELECT i.instructor_id, i.user_id, i.first_name, i.last_name, i.department FROM instructors i;
SELECT s.student_id, s.user_id, s.first_name, s.last_name, s.date_of_birth FROM students s;
SELECT c.course_id, c.course_code, c.course_name, c.instructor_id FROM courses c;
SELECT e.enrollment_id, e.student_id, e.course_id, e.enrollment_date FROM enrollments e;


-- ############################################################
-- FILE: 04_Verification.sql
-- ############################################################

-- =============================================================
-- Verification queries for DB_Timon (run after Lab 3)
-- =============================================================
USE DB_Timon;

-- 1. All tables and their columns
SELECT table_name, column_name, column_type, is_nullable, column_key, extra
FROM   information_schema.columns
WHERE  table_schema = 'DB_Timon'
ORDER  BY table_name, ordinal_position;

-- 2. Every foreign key constraint
SELECT table_name,
       constraint_name,
       column_name,
       referenced_table_name,
       referenced_column_name
FROM   information_schema.key_column_usage
WHERE  table_schema = 'DB_Timon'
  AND  referenced_table_name IS NOT NULL
ORDER  BY table_name, constraint_name;

-- 3. Unique constraints (including the 1:1 user links and enrollment rule)
SELECT table_name, index_name, column_name
FROM   information_schema.statistics
WHERE  table_schema = 'DB_Timon'
  AND  non_unique = 0
ORDER  BY table_name, index_name, seq_in_index;

-- 4. Login trace: user -> role -> profile
SELECT u.username,
       r.role_name,
       i.instructor_id,
       s.student_id
FROM   users u
JOIN   roles r ON r.role_id = u.role_id
LEFT JOIN instructors i ON i.user_id = u.user_id
LEFT JOIN students    s ON s.user_id = u.user_id
ORDER  BY u.user_id;

-- 5. Enrollment report
SELECT s.first_name AS student,
       c.course_code,
       c.course_name,
       i.last_name  AS instructor,
       e.enrollment_date
FROM   enrollments e
JOIN   students     s ON s.student_id    = e.student_id
JOIN   courses      c ON c.course_id     = e.course_id
LEFT JOIN instructors i ON i.instructor_id = c.instructor_id;


-- ############################################################
-- FILE: 05_Additional_Teachers_Students.sql
-- ############################################################

-- =============================================================
-- Additional seed data: teachers, students, courses, enrollments
-- Safe to re-run (INSERT IGNORE + NOT EXISTS guards).
-- =============================================================

USE DB_Timon;

-- -------------------------------------------------------------
-- 1. Teacher login accounts (role_id = 2)
--    Password format: pbkdf2_sha256$100000$<salt>$<hash>
-- -------------------------------------------------------------
INSERT IGNORE INTO users (username, password_hash, role_id) VALUES
('reyjay', 'pbkdf2_sha256$100000$VAKhkQp2E9DFD4sX135Akg==$M4smU7324sjDrYONl8bT238Zh3b+iOLiRhQ7nD00r2s=', 2),
('joseph','pbkdf2_sha256$100000$/xteG/wNBg3I30iTjd58Ew==$FIliiE4hV/NNrXReylEErmEMc7i/lZW24RLs1xXeJOM=', 2),
('ben',       'pbkdf2_sha256$100000$dGV+o6QvSGoXD+LpJ2Fz6Q==$vePE0Y6h+Fs5O2T8U9tl9Ot2teYm3RqSdsdLaSKau+o=', 2);

-- -------------------------------------------------------------
-- 2. Student login accounts (role_id = 3)
-- -------------------------------------------------------------
INSERT IGNORE INTO users (username, password_hash, role_id) VALUES
('steven', 'pbkdf2_sha256$100000$gG2W+/10GBH/NRSfufan4Q==$T0P1CB0ElGjLOUZ3OhKX4MtQiv6sqbRus7NLtDyKTnY=', 3),
('optimus', 'pbkdf2_sha256$100000$N++aSN9Alaf6VaFyvt9UqA==$C/pTYl5SSex3+csMakLFBt4MC/GwZs3Mn/TGDxnsxOs=', 3),
('evo',       'pbkdf2_sha256$100000$UJKzn7QNAOoEpf1s9aRvVw==$zDGBKYoZ8KaO4dJRtClxN4pRLqhlOTjuIqa9V/ls1nM=', 3),
('joe',       'pbkdf2_sha256$100000$oNr2E+xIRHufWl51moB5Sw==$F/mig8ZkLP0AZBiGGsPqq+RGfpAnGbI/+/0Kb2zJVgA=', 3);

-- -------------------------------------------------------------
-- 3. Instructor profiles (1:1 with the teacher accounts)
-- -------------------------------------------------------------
INSERT IGNORE INTO instructors (user_id, first_name, last_name, department)
SELECT u.user_id, 'Reyjay', 'Cagang', 'Computer Science'
FROM users u WHERE u.username = 'reyjay';

INSERT IGNORE INTO instructors (user_id, first_name, last_name, department)
SELECT u.user_id, 'Joseph', 'Sabello', 'Information Technology'
FROM users u WHERE u.username = 'joseph';

INSERT IGNORE INTO instructors (user_id, first_name, last_name, department)
SELECT u.user_id, 'Ben', 'Ten', 'Software Engineering'
FROM users u WHERE u.username = 'ben';

-- -------------------------------------------------------------
-- 4. Student profiles (1:1 with the student accounts)
-- -------------------------------------------------------------
INSERT IGNORE INTO students (user_id, first_name, last_name, date_of_birth)
SELECT u.user_id, 'Steven', 'Harley', '2003-08-12'
FROM users u WHERE u.username = 'steven';

INSERT IGNORE INTO students (user_id, first_name, last_name, date_of_birth)
SELECT u.user_id, 'Optimus', 'Prime', '2002-11-05'
FROM users u WHERE u.username = 'optimus';

INSERT IGNORE INTO students (user_id, first_name, last_name, date_of_birth)
SELECT u.user_id, 'Evo', 'Lin', '2004-02-18'
FROM users u WHERE u.username = 'evo';

INSERT IGNORE INTO students (user_id, first_name, last_name, date_of_birth)
SELECT u.user_id, 'Joe', 'Tan', '2003-06-30'
FROM users u WHERE u.username = 'joe';

-- -------------------------------------------------------------
-- 5. New courses, one per new teacher
-- -------------------------------------------------------------
INSERT IGNORE INTO courses (course_code, course_name, instructor_id)
SELECT 'CS301', 'Web Development', i.instructor_id
FROM instructors i JOIN users u ON u.user_id = i.user_id
WHERE u.username = 'reyjay';

INSERT IGNORE INTO courses (course_code, course_name, instructor_id)
SELECT 'CS401', 'Network Fundamentals', i.instructor_id
FROM instructors i JOIN users u ON u.user_id = i.user_id
WHERE u.username = 'joseph';

INSERT IGNORE INTO courses (course_code, course_name, instructor_id)
SELECT 'CS501', 'Artificial Intelligence', i.instructor_id
FROM instructors i JOIN users u ON u.user_id = i.user_id
WHERE u.username = 'ben';

-- -------------------------------------------------------------
-- 6. Enrollments (guarded against duplicates)
--    Steven Harley  -> CS101, CS301
--    Optimus Prime  -> CS201, CS501
--    Evo Lin        -> CS101, CS301, CS401
--    Joe Tan        -> CS201, CS401
-- -------------------------------------------------------------
INSERT INTO enrollments (student_id, course_id)
SELECT s.student_id, c.course_id
FROM users u
JOIN students s ON s.user_id = u.user_id
JOIN courses c ON c.course_code IN ('CS101', 'CS301')
WHERE u.username = 'steven'
  AND NOT EXISTS (SELECT 1 FROM enrollments e
                  WHERE e.student_id = s.student_id AND e.course_id = c.course_id);

INSERT INTO enrollments (student_id, course_id)
SELECT s.student_id, c.course_id
FROM users u
JOIN students s ON s.user_id = u.user_id
JOIN courses c ON c.course_code IN ('CS201', 'CS501')
WHERE u.username = 'optimus'
  AND NOT EXISTS (SELECT 1 FROM enrollments e
                  WHERE e.student_id = s.student_id AND e.course_id = c.course_id);

INSERT INTO enrollments (student_id, course_id)
SELECT s.student_id, c.course_id
FROM users u
JOIN students s ON s.user_id = u.user_id
JOIN courses c ON c.course_code IN ('CS101', 'CS301', 'CS401')
WHERE u.username = 'evo'
  AND NOT EXISTS (SELECT 1 FROM enrollments e
                  WHERE e.student_id = s.student_id AND e.course_id = c.course_id);

INSERT INTO enrollments (student_id, course_id)
SELECT s.student_id, c.course_id
FROM users u
JOIN students s ON s.user_id = u.user_id
JOIN courses c ON c.course_code IN ('CS201', 'CS401')
WHERE u.username = 'joe'
  AND NOT EXISTS (SELECT 1 FROM enrollments e
                  WHERE e.student_id = s.student_id AND e.course_id = c.course_id);

-- -------------------------------------------------------------
-- Verification
-- -------------------------------------------------------------
SELECT u.user_id, u.username, r.role_name
FROM users u JOIN roles r ON r.role_id = u.role_id
ORDER BY u.user_id;

SELECT i.instructor_id, u.username, i.first_name, i.last_name, i.department
FROM instructors i JOIN users u ON u.user_id = i.user_id
ORDER BY i.instructor_id;

SELECT s.student_id, u.username, s.first_name, s.last_name, s.date_of_birth
FROM students s JOIN users u ON u.user_id = s.user_id
ORDER BY s.student_id;

SELECT c.course_code, c.course_name, i.last_name AS instructor
FROM courses c LEFT JOIN instructors i ON i.instructor_id = c.instructor_id
ORDER BY c.course_code;

SELECT s.first_name, s.last_name, c.course_code, c.course_name
FROM enrollments e
JOIN students s ON s.student_id = e.student_id
JOIN courses c ON c.course_id = e.course_id
ORDER BY s.student_id, c.course_code;


-- ############################################################
-- FILE: 06_Update_Usernames_Passwords.sql
-- ############################################################

-- =============================================================
-- Rename the added accounts to first-name usernames and reset
-- their passwords to <firstname>123.
--
-- Run once after 05_Additional_Teachers_Students.sql.
-- Re-running is harmless: the old usernames will no longer match.
-- =============================================================

USE DB_Timon;

UPDATE users SET username = 'reyjay',
  password_hash = 'pbkdf2_sha256$100000$VAKhkQp2E9DFD4sX135Akg==$M4smU7324sjDrYONl8bT238Zh3b+iOLiRhQ7nD00r2s='
WHERE username = 'reyjay.cagang';

UPDATE users SET username = 'joseph',
  password_hash = 'pbkdf2_sha256$100000$/xteG/wNBg3I30iTjd58Ew==$FIliiE4hV/NNrXReylEErmEMc7i/lZW24RLs1xXeJOM='
WHERE username = 'joseph.sabello';

UPDATE users SET username = 'ben',
  password_hash = 'pbkdf2_sha256$100000$dGV+o6QvSGoXD+LpJ2Fz6Q==$vePE0Y6h+Fs5O2T8U9tl9Ot2teYm3RqSdsdLaSKau+o='
WHERE username = 'ben.ten';

UPDATE users SET username = 'steven',
  password_hash = 'pbkdf2_sha256$100000$gG2W+/10GBH/NRSfufan4Q==$T0P1CB0ElGjLOUZ3OhKX4MtQiv6sqbRus7NLtDyKTnY='
WHERE username = 'steven.harley';

UPDATE users SET username = 'optimus',
  password_hash = 'pbkdf2_sha256$100000$N++aSN9Alaf6VaFyvt9UqA==$C/pTYl5SSex3+csMakLFBt4MC/GwZs3Mn/TGDxnsxOs='
WHERE username = 'optimus.prime';

UPDATE users SET username = 'evo',
  password_hash = 'pbkdf2_sha256$100000$UJKzn7QNAOoEpf1s9aRvVw==$zDGBKYoZ8KaO4dJRtClxN4pRLqhlOTjuIqa9V/ls1nM='
WHERE username = 'evo.lin';

UPDATE users SET username = 'joe',
  password_hash = 'pbkdf2_sha256$100000$oNr2E+xIRHufWl51moB5Sw==$F/mig8ZkLP0AZBiGGsPqq+RGfpAnGbI/+/0Kb2zJVgA='
WHERE username = 'joe.tan';

-- Verification
SELECT u.user_id, u.username, r.role_name
FROM users u JOIN roles r ON r.role_id = u.role_id
ORDER BY u.user_id;


-- ############################################################
-- FILE: 07_Safe_If_Exists_Setup.sql
-- ############################################################

-- =============================================================
-- SAFE SETUP FOR DB_Timon - "IF ALREADY EXISTS, SAY SO"
-- =============================================================
-- This script does NOT drop or overwrite anything.
-- For every object it first reports whether the object already
-- exists, then creates it only when it is missing.
-- Re-running it is completely safe: existing databases, tables
-- and rows are preserved and reported as "already exists".
-- =============================================================

-- -------------------------------------------------------------
-- 1. DATABASE
-- -------------------------------------------------------------
SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.SCHEMATA
            WHERE SCHEMA_NAME = 'DB_Timon'),
    'Database DB_Timon already exists',
    'Database DB_Timon does not exist yet - creating it'
) AS database_status;

CREATE DATABASE IF NOT EXISTS DB_Timon
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE DB_Timon;

-- -------------------------------------------------------------
-- 2. TABLES - report status, then create only if missing
-- -------------------------------------------------------------
SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = 'DB_Timon' AND TABLE_NAME = 'roles'),
    'Table roles already exists',
    'Table roles will be created'
) AS roles_status;

CREATE TABLE IF NOT EXISTS roles (
    role_id    INT          NOT NULL AUTO_INCREMENT,
    role_name  VARCHAR(50)  NOT NULL UNIQUE,
    PRIMARY KEY (role_id)
) ENGINE = InnoDB;

SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = 'DB_Timon' AND TABLE_NAME = 'users'),
    'Table users already exists',
    'Table users will be created'
) AS users_status;

CREATE TABLE IF NOT EXISTS users (
    user_id       INT          NOT NULL AUTO_INCREMENT,
    username      VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id       INT          NOT NULL,
    PRIMARY KEY (user_id),
    CONSTRAINT fk_users_role
        FOREIGN KEY (role_id) REFERENCES roles (role_id)
) ENGINE = InnoDB;

SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = 'DB_Timon' AND TABLE_NAME = 'instructors'),
    'Table instructors already exists',
    'Table instructors will be created'
) AS instructors_status;

CREATE TABLE IF NOT EXISTS instructors (
    instructor_id  INT          NOT NULL AUTO_INCREMENT,
    user_id        INT          NOT NULL UNIQUE,
    first_name     VARCHAR(100) NOT NULL,
    last_name      VARCHAR(100) NOT NULL,
    department     VARCHAR(100) NULL,
    PRIMARY KEY (instructor_id),
    CONSTRAINT fk_instructors_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE = InnoDB;

SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = 'DB_Timon' AND TABLE_NAME = 'students'),
    'Table students already exists',
    'Table students will be created'
) AS students_status;

CREATE TABLE IF NOT EXISTS students (
    student_id     INT          NOT NULL AUTO_INCREMENT,
    user_id        INT          NOT NULL UNIQUE,
    first_name     VARCHAR(100) NOT NULL,
    last_name      VARCHAR(100) NOT NULL,
    date_of_birth  DATE         NULL,
    PRIMARY KEY (student_id),
    CONSTRAINT fk_students_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE = InnoDB;

SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = 'DB_Timon' AND TABLE_NAME = 'courses'),
    'Table courses already exists',
    'Table courses will be created'
) AS courses_status;

CREATE TABLE IF NOT EXISTS courses (
    course_id     INT          NOT NULL AUTO_INCREMENT,
    course_code   VARCHAR(50)  NOT NULL UNIQUE,
    course_name   VARCHAR(255) NOT NULL,
    instructor_id INT          NULL,
    PRIMARY KEY (course_id),
    CONSTRAINT fk_courses_instructor
        FOREIGN KEY (instructor_id) REFERENCES instructors (instructor_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE = InnoDB;

SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = 'DB_Timon' AND TABLE_NAME = 'enrollments'),
    'Table enrollments already exists',
    'Table enrollments will be created'
) AS enrollments_status;

CREATE TABLE IF NOT EXISTS enrollments (
    enrollment_id   INT      NOT NULL AUTO_INCREMENT,
    student_id      INT      NOT NULL,
    course_id       INT      NOT NULL,
    enrollment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (enrollment_id),
    CONSTRAINT unique_enrollment UNIQUE (student_id, course_id),
    CONSTRAINT fk_enrollments_student
        FOREIGN KEY (student_id) REFERENCES students (student_id),
    CONSTRAINT fk_enrollments_course
        FOREIGN KEY (course_id) REFERENCES courses (course_id)
) ENGINE = InnoDB;

-- -------------------------------------------------------------
-- 3. ROLES - insert only missing rows
-- -------------------------------------------------------------
INSERT IGNORE INTO roles (role_id, role_name) VALUES
    (1, 'Admin'),
    (2, 'Teacher'),
    (3, 'Student');

SELECT IF(
    (SELECT COUNT(*) FROM roles) >= 3,
    'Roles data already exists',
    'Roles data inserted'
) AS roles_data_status;

-- -------------------------------------------------------------
-- 4. USERS - insert only missing usernames (final credentials)
-- -------------------------------------------------------------
INSERT IGNORE INTO users (username, password_hash, role_id) VALUES
 ('admin',    'pbkdf2_sha256$100000$YsTsBdEifNDP+dlL5TPp5A==$/7gsFUtdJyc2jOAP8yPtIDkBFXJ8t2F9GkVlEqtT/Eg=', 1),
 ('teacher1', 'pbkdf2_sha256$100000$tLOviNFFzugAUF3eXpbgaw==$4k0nn0fTYHzfSnIBg7EeNHHzhGtBZ62pHmcJqGAig/Y=', 2),
 ('student1', 'pbkdf2_sha256$100000$QdDT5d7/dC8bLCyGX89TXQ==$y09RkfXh5X9P49viWzjgkbO1gURKStt0qQYWXe+htHc=', 3),
 ('reyjay',   'pbkdf2_sha256$100000$VAKhkQp2E9DFD4sX135Akg==$M4smU7324sjDrYONl8bT238Zh3b+iOLiRhQ7nD00r2s=', 2),
 ('joseph',   'pbkdf2_sha256$100000$/xteG/wNBg3I30iTjd58Ew==$FIliiE4hV/NNrXReylEErmEMc7i/lZW24RLs1xXeJOM=', 2),
 ('ben',      'pbkdf2_sha256$100000$dGV+o6QvSGoXD+LpJ2Fz6Q==$vePE0Y6h+Fs5O2T8U9tl9Ot2teYm3RqSdsdLaSKau+o=', 2),
 ('steven',   'pbkdf2_sha256$100000$gG2W+/10GBH/NRSfufan4Q==$T0P1CB0ElGjLOUZ3OhKX4MtQiv6sqbRus7NLtDyKTnY=', 3),
 ('optimus',  'pbkdf2_sha256$100000$N++aSN9Alaf6VaFyvt9UqA==$C/pTYl5SSex3+csMakLFBt4MC/GwZs3Mn/TGDxnsxOs=', 3),
 ('evo',      'pbkdf2_sha256$100000$UJKzn7QNAOoEpf1s9aRvVw==$zDGBKYoZ8KaO4dJRtClxN4pRLqhlOTjuIqa9V/ls1nM=', 3),
 ('joe',      'pbkdf2_sha256$100000$oNr2E+xIRHufWl51moB5Sw==$F/mig8ZkLP0AZBiGGsPqq+RGfpAnGbI/+/0Kb2zJVgA=', 3);

SELECT IF(
    (SELECT COUNT(*) FROM users) >= 10,
    'User accounts already exist',
    'User accounts inserted'
) AS users_data_status;

-- -------------------------------------------------------------
-- 5. INSTRUCTOR / STUDENT PROFILES - only if profile missing
-- -------------------------------------------------------------
INSERT INTO instructors (user_id, first_name, last_name, department)
SELECT u.user_id, 'Alan', 'Turing', 'Computer Science'
FROM users u WHERE u.username = 'teacher1'
  AND NOT EXISTS (SELECT 1 FROM instructors i WHERE i.user_id = u.user_id);

INSERT INTO instructors (user_id, first_name, last_name, department)
SELECT u.user_id, 'Reyjay', 'Cagang', 'Computer Science'
FROM users u WHERE u.username = 'reyjay'
  AND NOT EXISTS (SELECT 1 FROM instructors i WHERE i.user_id = u.user_id);

INSERT INTO instructors (user_id, first_name, last_name, department)
SELECT u.user_id, 'Joseph', 'Sabello', 'Information Technology'
FROM users u WHERE u.username = 'joseph'
  AND NOT EXISTS (SELECT 1 FROM instructors i WHERE i.user_id = u.user_id);

INSERT INTO instructors (user_id, first_name, last_name, department)
SELECT u.user_id, 'Ben', 'Ten', 'Software Engineering'
FROM users u WHERE u.username = 'ben'
  AND NOT EXISTS (SELECT 1 FROM instructors i WHERE i.user_id = u.user_id);

INSERT INTO students (user_id, first_name, last_name, date_of_birth)
SELECT u.user_id, 'Juan', 'Dela Cruz', '2003-05-14'
FROM users u WHERE u.username = 'student1'
  AND NOT EXISTS (SELECT 1 FROM students s WHERE s.user_id = u.user_id);

INSERT INTO students (user_id, first_name, last_name, date_of_birth)
SELECT u.user_id, 'Steven', 'Harley', '2003-08-12'
FROM users u WHERE u.username = 'steven'
  AND NOT EXISTS (SELECT 1 FROM students s WHERE s.user_id = u.user_id);

INSERT INTO students (user_id, first_name, last_name, date_of_birth)
SELECT u.user_id, 'Optimus', 'Prime', '2002-11-05'
FROM users u WHERE u.username = 'optimus'
  AND NOT EXISTS (SELECT 1 FROM students s WHERE s.user_id = u.user_id);

INSERT INTO students (user_id, first_name, last_name, date_of_birth)
SELECT u.user_id, 'Evo', 'Lin', '2004-02-18'
FROM users u WHERE u.username = 'evo'
  AND NOT EXISTS (SELECT 1 FROM students s WHERE s.user_id = u.user_id);

INSERT INTO students (user_id, first_name, last_name, date_of_birth)
SELECT u.user_id, 'Joe', 'Tan', '2003-06-30'
FROM users u WHERE u.username = 'joe'
  AND NOT EXISTS (SELECT 1 FROM students s WHERE s.user_id = u.user_id);

SELECT IF(
    (SELECT COUNT(*) FROM instructors) >= 4,
    'Instructor profiles already exist',
    'Instructor profiles inserted'
) AS instructors_data_status;

SELECT IF(
    (SELECT COUNT(*) FROM students) >= 5,
    'Student profiles already exist',
    'Student profiles inserted'
) AS students_data_status;

-- -------------------------------------------------------------
-- 6. COURSES - insert only if course_code missing
-- -------------------------------------------------------------
INSERT IGNORE INTO courses (course_code, course_name, instructor_id)
SELECT 'CS101', 'Introduction to Programming', i.instructor_id
FROM instructors i JOIN users u ON u.user_id = i.user_id
WHERE u.username = 'teacher1';

INSERT IGNORE INTO courses (course_code, course_name, instructor_id)
SELECT 'CS201', 'Database Systems', i.instructor_id
FROM instructors i JOIN users u ON u.user_id = i.user_id
WHERE u.username = 'teacher1';

INSERT IGNORE INTO courses (course_code, course_name, instructor_id)
SELECT 'CS301', 'Web Development', i.instructor_id
FROM instructors i JOIN users u ON u.user_id = i.user_id
WHERE u.username = 'reyjay';

INSERT IGNORE INTO courses (course_code, course_name, instructor_id)
SELECT 'CS401', 'Network Fundamentals', i.instructor_id
FROM instructors i JOIN users u ON u.user_id = i.user_id
WHERE u.username = 'joseph';

INSERT IGNORE INTO courses (course_code, course_name, instructor_id)
SELECT 'CS501', 'Artificial Intelligence', i.instructor_id
FROM instructors i JOIN users u ON u.user_id = i.user_id
WHERE u.username = 'ben';

SELECT IF(
    (SELECT COUNT(*) FROM courses) >= 5,
    'Courses already exist',
    'Courses inserted'
) AS courses_data_status;

-- -------------------------------------------------------------
-- 7. ENROLLMENTS - insert only if the pair is missing
-- -------------------------------------------------------------
INSERT INTO enrollments (student_id, course_id)
SELECT s.student_id, c.course_id
FROM users u
JOIN students s ON s.user_id = u.user_id
JOIN courses c ON c.course_code IN ('CS101', 'CS201')
WHERE u.username = 'student1'
  AND NOT EXISTS (SELECT 1 FROM enrollments e
                  WHERE e.student_id = s.student_id AND e.course_id = c.course_id);

INSERT INTO enrollments (student_id, course_id)
SELECT s.student_id, c.course_id
FROM users u
JOIN students s ON s.user_id = u.user_id
JOIN courses c ON c.course_code IN ('CS101', 'CS301')
WHERE u.username = 'steven'
  AND NOT EXISTS (SELECT 1 FROM enrollments e
                  WHERE e.student_id = s.student_id AND e.course_id = c.course_id);

INSERT INTO enrollments (student_id, course_id)
SELECT s.student_id, c.course_id
FROM users u
JOIN students s ON s.user_id = u.user_id
JOIN courses c ON c.course_code IN ('CS201', 'CS501')
WHERE u.username = 'optimus'
  AND NOT EXISTS (SELECT 1 FROM enrollments e
                  WHERE e.student_id = s.student_id AND e.course_id = c.course_id);

INSERT INTO enrollments (student_id, course_id)
SELECT s.student_id, c.course_id
FROM users u
JOIN students s ON s.user_id = u.user_id
JOIN courses c ON c.course_code IN ('CS101', 'CS301', 'CS401')
WHERE u.username = 'evo'
  AND NOT EXISTS (SELECT 1 FROM enrollments e
                  WHERE e.student_id = s.student_id AND e.course_id = c.course_id);

INSERT INTO enrollments (student_id, course_id)
SELECT s.student_id, c.course_id
FROM users u
JOIN students s ON s.user_id = u.user_id
JOIN courses c ON c.course_code IN ('CS201', 'CS401')
WHERE u.username = 'joe'
  AND NOT EXISTS (SELECT 1 FROM enrollments e
                  WHERE e.student_id = s.student_id AND e.course_id = c.course_id);

SELECT IF(
    (SELECT COUNT(*) FROM enrollments) >= 11,
    'Enrollment data already exists',
    'Enrollment data inserted'
) AS enrollments_data_status;

-- -------------------------------------------------------------
-- 8. FINAL SUMMARY - one row per object
-- -------------------------------------------------------------
SELECT 'Database' AS object_type, 'DB_Timon' AS object_name,
       IF(EXISTS(SELECT 1 FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='DB_Timon'),
          'already exists', 'created') AS status
UNION ALL
SELECT 'Table', t.table_name,
       'already exists'
FROM information_schema.tables t
WHERE t.table_schema = 'DB_Timon'
  AND t.table_name IN ('roles','users','instructors','students','courses','enrollments')
ORDER BY object_name;


-- ############################################################
-- FILE: 08_Lab4_Gradebook.sql
-- ############################################################

-- =============================================================
-- LABORATORY EXERCISE 4 - ADVANCED DATA INTEGRITY,
--                          GRADEBOOK MANAGEMENT & ROLE-BASED DASHBOARDS
-- Database: DB_Timon
-- Requires: 01..07 (students, courses, instructors, enrollments, users)
--
-- SAFE / RE-RUNNABLE: no DROP of tables and no DELETE of data.
-- For every object a status is printed first, then the object is
-- created only if it is missing (views use CREATE OR REPLACE VIEW;
-- seed rows use INSERT IGNORE / NOT EXISTS guards).
-- =============================================================

USE DB_Timon;

-- -------------------------------------------------------------
-- 1. assignment_types - standardized assessment categories
-- -------------------------------------------------------------
SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'assignment_types'),
    'Table assignment_types already exists',
    'Table assignment_types will be created'
) AS assignment_types_status;

CREATE TABLE IF NOT EXISTS assignment_types (
    type_id        INT           NOT NULL AUTO_INCREMENT,
    type_name      VARCHAR(100)  NOT NULL UNIQUE,
    default_weight DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
    PRIMARY KEY (type_id),
    CONSTRAINT chk_default_weight_range
        CHECK (default_weight >= 0.00 AND default_weight <= 100.00)
) ENGINE = InnoDB;

-- -------------------------------------------------------------
-- 2. grades - ternary relationship Students x Courses x Types
--    Composite PK = one grade per student / course / type.
--    date_recorded defaults to the current date/time.
-- -------------------------------------------------------------
SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'grades'),
    'Table grades already exists',
    'Table grades will be created'
) AS grades_status;

CREATE TABLE IF NOT EXISTS grades (
    student_id    INT          NOT NULL,
    course_id     INT          NOT NULL,
    type_id       INT          NOT NULL,
    grade         DECIMAL(5,2) NULL,
    date_recorded DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (student_id, course_id, type_id),
    CONSTRAINT fk_grades_student
        FOREIGN KEY (student_id) REFERENCES students (student_id),
    CONSTRAINT fk_grades_course
        FOREIGN KEY (course_id) REFERENCES courses (course_id),
    CONSTRAINT fk_grades_type
        FOREIGN KEY (type_id) REFERENCES assignment_types (type_id),
    CONSTRAINT chk_grade_range
        CHECK (grade IS NULL OR (grade >= 0.00 AND grade <= 100.00))
) ENGINE = InnoDB;

-- -------------------------------------------------------------
-- 3. Views for role-based dashboards
-- -------------------------------------------------------------
SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.VIEWS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'student_grade_summary'),
    'View student_grade_summary already exists - definition refreshed',
    'View student_grade_summary will be created'
) AS student_grade_summary_status;

CREATE OR REPLACE VIEW student_grade_summary AS
SELECT  s.student_id,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        c.course_code,
        c.course_name,
        at.type_name,
        g.grade,
        g.date_recorded
FROM    grades g
JOIN    students s          ON s.student_id = g.student_id
JOIN    courses c           ON c.course_id  = g.course_id
JOIN    assignment_types at ON at.type_id   = g.type_id;

SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.VIEWS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teacher_course_overview'),
    'View teacher_course_overview already exists - definition refreshed',
    'View teacher_course_overview will be created'
) AS teacher_course_overview_status;

CREATE OR REPLACE VIEW teacher_course_overview AS
SELECT  i.instructor_id,
        i.user_id,
        c.course_id,
        c.course_code,
        c.course_name,
        at.type_name,
        COUNT(g.grade)  AS submissions,
        AVG(g.grade)    AS average_grade
FROM    courses c
JOIN    instructors i       ON i.instructor_id = c.instructor_id
LEFT JOIN grades g         ON g.course_id      = c.course_id
LEFT JOIN assignment_types at ON at.type_id    = g.type_id
GROUP BY i.instructor_id, i.user_id, c.course_id,
         c.course_code, c.course_name, at.type_id, at.type_name;

-- -------------------------------------------------------------
-- 4. Seed assignment types (weights total 100%)
-- -------------------------------------------------------------
INSERT IGNORE INTO assignment_types (type_name, default_weight) VALUES
    ('Homework',    20.00),
    ('Quiz',        20.00),
    ('Midterm',     25.00),
    ('Final Exam',  35.00);

SELECT IF(
    (SELECT COUNT(*) FROM assignment_types) >= 4,
    'Assignment type seed data already exists',
    'Assignment type seed data inserted'
) AS assignment_types_data_status;

-- -------------------------------------------------------------
-- 5. Sample grades for the existing students and their enrollments.
--    The NOT EXISTS guard makes re-runs safe: a grade that is
--    already recorded (even a NULL or a teacher-entered value)
--    is never overwritten or duplicated.
-- -------------------------------------------------------------
INSERT INTO grades (student_id, course_id, type_id, grade)
SELECT  s.student_id, c.course_id, at.type_id, v.grade
FROM (
    SELECT 'student1' AS username, 'CS101' AS course_code, 'Homework'   AS type_name, CAST(92.00 AS DECIMAL(5,2)) AS grade
    UNION ALL SELECT 'student1', 'CS101', 'Quiz',       88.00
    UNION ALL SELECT 'student1', 'CS101', 'Midterm',    85.00
    UNION ALL SELECT 'student1', 'CS101', 'Final Exam', 90.00
    UNION ALL SELECT 'student1', 'CS201', 'Homework',   78.00
    UNION ALL SELECT 'student1', 'CS201', 'Quiz',       82.00
    UNION ALL SELECT 'student1', 'CS201', 'Midterm',    80.00
    UNION ALL SELECT 'student1', 'CS201', 'Final Exam', 84.00

    UNION ALL SELECT 'steven',  'CS101', 'Homework',    85.00
    UNION ALL SELECT 'steven',  'CS101', 'Quiz',        90.00
    UNION ALL SELECT 'steven',  'CS101', 'Midterm',     88.00
    UNION ALL SELECT 'steven',  'CS101', 'Final Exam',  92.00
    UNION ALL SELECT 'steven',  'CS301', 'Homework',    88.00
    UNION ALL SELECT 'steven',  'CS301', 'Quiz',        84.00
    UNION ALL SELECT 'steven',  'CS301', 'Midterm',     90.00
    UNION ALL SELECT 'steven',  'CS301', 'Final Exam',  86.00

    UNION ALL SELECT 'optimus', 'CS201', 'Homework',    95.00
    UNION ALL SELECT 'optimus', 'CS201', 'Quiz',        92.00
    UNION ALL SELECT 'optimus', 'CS201', 'Midterm',     96.00
    UNION ALL SELECT 'optimus', 'CS201', 'Final Exam',  94.00
    UNION ALL SELECT 'optimus', 'CS501', 'Homework',    90.00
    UNION ALL SELECT 'optimus', 'CS501', 'Quiz',        88.00
    UNION ALL SELECT 'optimus', 'CS501', 'Midterm',     92.00
    UNION ALL SELECT 'optimus', 'CS501', 'Final Exam',  91.00

    UNION ALL SELECT 'evo',     'CS101', 'Homework',    75.00
    UNION ALL SELECT 'evo',     'CS101', 'Quiz',        80.00
    UNION ALL SELECT 'evo',     'CS101', 'Midterm',     78.00
    UNION ALL SELECT 'evo',     'CS101', 'Final Exam',  82.00
    UNION ALL SELECT 'evo',     'CS301', 'Homework',    84.00
    UNION ALL SELECT 'evo',     'CS301', 'Quiz',        86.00
    UNION ALL SELECT 'evo',     'CS301', 'Midterm',     82.00
    UNION ALL SELECT 'evo',     'CS301', 'Final Exam',  88.00
    UNION ALL SELECT 'evo',     'CS401', 'Homework',    80.00
    UNION ALL SELECT 'evo',     'CS401', 'Quiz',        85.00
    UNION ALL SELECT 'evo',     'CS401', 'Midterm',     83.00
    UNION ALL SELECT 'evo',     'CS401', 'Final Exam',  87.00

    UNION ALL SELECT 'joe',     'CS201', 'Homework',    70.00
    UNION ALL SELECT 'joe',     'CS201', 'Quiz',        75.00
    UNION ALL SELECT 'joe',     'CS201', 'Midterm',     72.00
    UNION ALL SELECT 'joe',     'CS201', 'Final Exam',  78.00
    UNION ALL SELECT 'joe',     'CS401', 'Homework',    85.00
    UNION ALL SELECT 'joe',     'CS401', 'Quiz',        88.00
    UNION ALL SELECT 'joe',     'CS401', 'Midterm',     84.00
    UNION ALL SELECT 'joe',     'CS401', 'Final Exam',  86.00
) v
JOIN    users u             ON u.username  = v.username
JOIN    students s          ON s.user_id   = u.user_id
JOIN    courses c           ON c.course_code = v.course_code
JOIN    assignment_types at ON at.type_name  = v.type_name
WHERE NOT EXISTS (
    SELECT 1 FROM grades g
    WHERE  g.student_id = s.student_id
       AND g.course_id  = c.course_id
       AND g.type_id    = at.type_id
);

SELECT IF(
    (SELECT COUNT(*) FROM grades) >= 44,
    'Sample grade data already exists',
    'Sample grade data inserted'
) AS grades_data_status;

-- -------------------------------------------------------------
-- 6. Verification / demonstration
-- -------------------------------------------------------------
SELECT 'Table' AS object_type, table_name AS object_name, 'already exists' AS status
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND table_name IN ('assignment_types', 'grades')
UNION ALL
SELECT 'View', table_name, 'already exists'
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE()
  AND table_name IN ('student_grade_summary', 'teacher_course_overview')
ORDER BY object_type, object_name;

SELECT type_id, type_name, default_weight FROM assignment_types ORDER BY type_id;
SELECT COUNT(*) AS total_grades FROM grades;

-- Student dashboard sample: Juan (student_id 1)
SELECT * FROM student_grade_summary WHERE student_id = 1 ORDER BY course_code, type_name;

-- Teacher dashboard sample: teacher1 (user_id 2)
SELECT * FROM teacher_course_overview WHERE user_id = 2 ORDER BY course_code, type_name;


-- ############################################################
-- FILE: 09_Lab5_Performance_Procedures.sql
-- ############################################################

-- =============================================================
-- LABORATORY EXERCISE 5 - DATABASE PERFORMANCE, STORED PROCEDURES
--                          & ADVANCED REPORTING
-- Database: DB_Timon
-- Requires: 01..08 (grades, assignment_types, enrollments, courses,
--                   instructors, students and their seed data)
--
-- SAFE / RE-RUNNABLE: no table is dropped and no row is deleted.
-- Indexes are created only when missing; views are replaced with
-- CREATE OR REPLACE VIEW; procedures report "already exists" and
-- have their definition refreshed (no data is affected).
-- =============================================================

USE DB_Timon;

-- -------------------------------------------------------------
-- 1. Performance-optimizing indexes
--    MariaDB-safe guarded creation via information_schema + PREPARE
-- -------------------------------------------------------------
SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'grades'
              AND INDEX_NAME = 'idx_grades_student_course'),
    'Index idx_grades_student_course already exists',
    'Index idx_grades_student_course will be created'
) AS idx_grades_student_course_status;

SET @idx_sql = IF(
    EXISTS (SELECT 1 FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'grades'
              AND INDEX_NAME = 'idx_grades_student_course'),
    'DO 0',
    'CREATE INDEX idx_grades_student_course ON grades (student_id, course_id)');
PREPARE stmt FROM @idx_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'enrollments'
              AND INDEX_NAME = 'idx_enrollments_date'),
    'Index idx_enrollments_date already exists',
    'Index idx_enrollments_date will be created'
) AS idx_enrollments_date_status;

SET @idx_sql = IF(
    EXISTS (SELECT 1 FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'enrollments'
              AND INDEX_NAME = 'idx_enrollments_date'),
    'DO 0',
    'CREATE INDEX idx_enrollments_date ON enrollments (enrollment_date)');
PREPARE stmt FROM @idx_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'courses'
              AND INDEX_NAME = 'idx_courses_code_name'),
    'Index idx_courses_code_name already exists',
    'Index idx_courses_code_name will be created'
) AS idx_courses_code_name_status;

SET @idx_sql = IF(
    EXISTS (SELECT 1 FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'courses'
              AND INDEX_NAME = 'idx_courses_code_name'),
    'DO 0',
    'CREATE INDEX idx_courses_code_name ON courses (course_code, course_name)');
PREPARE stmt FROM @idx_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -------------------------------------------------------------
-- 2. Stored procedure sp_EnrollStudent
--    Validation + transaction + SQLEXCEPTION handler with ROLLBACK.
--    Only the routine definition is refreshed on a re-run; data is
--    never removed by this script.
-- -------------------------------------------------------------
SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.ROUTINES
            WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'sp_EnrollStudent'),
    'Procedure sp_EnrollStudent already exists - definition refreshed',
    'Procedure sp_EnrollStudent will be created'
) AS sp_EnrollStudent_status;

DROP PROCEDURE IF EXISTS sp_EnrollStudent;

DELIMITER //
CREATE PROCEDURE sp_EnrollStudent(
    IN  p_student_id INT,
    IN  p_course_id  INT,
    OUT p_message    VARCHAR(255))
BEGIN
    DECLARE v_student_exists  INT DEFAULT 0;
    DECLARE v_course_exists   INT DEFAULT 0;
    DECLARE v_duplicate       INT DEFAULT 0;
    DECLARE v_error_message   TEXT DEFAULT 'Enrollment failed';

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        SET p_message = CONCAT('Error: ', v_error_message);
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_student_exists
    FROM students WHERE student_id = p_student_id;

    SELECT COUNT(*) INTO v_course_exists
    FROM courses WHERE course_id = p_course_id;

    SELECT COUNT(*) INTO v_duplicate
    FROM enrollments
    WHERE student_id = p_student_id AND course_id = p_course_id;

    IF v_student_exists = 0 THEN
        ROLLBACK;
        SET p_message = 'Error: Student not found';
    ELSEIF v_course_exists = 0 THEN
        ROLLBACK;
        SET p_message = 'Error: Course not found';
    ELSEIF v_duplicate > 0 THEN
        ROLLBACK;
        SET p_message = 'Error: Student already enrolled in this course';
    ELSE
        INSERT INTO enrollments (student_id, course_id)
        VALUES (p_student_id, p_course_id);
        COMMIT;
        SET p_message = 'Success: Student enrolled successfully';
    END IF;
END//
DELIMITER ;

-- -------------------------------------------------------------
-- 3. Stored procedure sp_CalculateCourseGrade
--    Weighted average: SUM(grade * default_weight) / SUM(default_weight)
--    over every graded assignment of the student. Returns 0.00 when
--    there are no grades or the weights add up to zero.
-- -------------------------------------------------------------
SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.ROUTINES
            WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'sp_CalculateCourseGrade'),
    'Procedure sp_CalculateCourseGrade already exists - definition refreshed',
    'Procedure sp_CalculateCourseGrade will be created'
) AS sp_CalculateCourseGrade_status;

DROP PROCEDURE IF EXISTS sp_CalculateCourseGrade;

DELIMITER //
CREATE PROCEDURE sp_CalculateCourseGrade(
    IN  p_student_id  INT,
    OUT p_final_grade DECIMAL(5,2))
BEGIN
    DECLARE v_weight_sum DECIMAL(10,2) DEFAULT 0.00;

    SELECT SUM(at.default_weight)
      INTO v_weight_sum
      FROM grades g
      JOIN assignment_types at ON at.type_id = g.type_id
     WHERE g.student_id = p_student_id
       AND g.grade IS NOT NULL;

    IF v_weight_sum IS NULL OR v_weight_sum = 0 THEN
        SET p_final_grade = 0.00;
    ELSE
        SELECT ROUND(SUM(g.grade * at.default_weight) / v_weight_sum, 2)
          INTO p_final_grade
          FROM grades g
          JOIN assignment_types at ON at.type_id = g.type_id
         WHERE g.student_id = p_student_id
           AND g.grade IS NOT NULL;
    END IF;
END//
DELIMITER ;

-- -------------------------------------------------------------
-- 4. Advanced reporting views
-- -------------------------------------------------------------
SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.VIEWS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'student_transcript'),
    'View student_transcript already exists - definition refreshed',
    'View student_transcript will be created'
) AS student_transcript_status;

CREATE OR REPLACE VIEW student_transcript AS
SELECT  s.student_id,
        CONCAT(s.first_name, ' ', s.last_name)        AS student_name,
        c.course_code,
        c.course_name,
        at.type_name                                  AS assignment_type,
        at.default_weight,
        g.grade,
        e.enrollment_date,
        COALESCE(CONCAT(i.first_name, ' ', i.last_name), 'Unassigned') AS instructor_name
FROM    students s
JOIN    enrollments e            ON e.student_id = s.student_id
JOIN    courses c                ON c.course_id  = e.course_id
LEFT JOIN instructors i         ON i.instructor_id = c.instructor_id
LEFT JOIN grades g              ON g.student_id = s.student_id
                               AND g.course_id  = c.course_id
LEFT JOIN assignment_types at   ON at.type_id   = g.type_id;

SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.VIEWS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'course_performance_analytics'),
    'View course_performance_analytics already exists - definition refreshed',
    'View course_performance_analytics will be created'
) AS course_performance_analytics_status;

-- The enrollment and grade figures are aggregated in separate derived
-- tables first. Joining the raw tables directly would multiply each
-- grade by the number of enrollments in the course.
CREATE OR REPLACE VIEW course_performance_analytics AS
SELECT  c.course_id,
        c.course_code,
        c.course_name,
        COALESCE(CONCAT(i.first_name, ' ', i.last_name), 'Unassigned') AS instructor_name,
        COALESCE(e.enrolled_students, 0) AS enrolled_students,
        COALESCE(g.grades_submitted, 0)  AS grades_submitted,
        g.average_grade,
        g.minimum_grade,
        g.maximum_grade
FROM    courses c
LEFT JOIN instructors i ON i.instructor_id = c.instructor_id
LEFT JOIN (
    SELECT course_id, COUNT(DISTINCT student_id) AS enrolled_students
    FROM enrollments
    GROUP BY course_id
) e ON e.course_id = c.course_id
LEFT JOIN (
    SELECT course_id,
           COUNT(grade) AS grades_submitted,
           ROUND(AVG(grade), 2) AS average_grade,
           MIN(grade) AS minimum_grade,
           MAX(grade) AS maximum_grade
    FROM grades
    GROUP BY course_id
) g ON g.course_id = c.course_id;

-- -------------------------------------------------------------
-- 5. Verification - index inventory
-- -------------------------------------------------------------
SELECT TABLE_NAME, INDEX_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS columns_in_index
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
  AND INDEX_NAME IN ('idx_grades_student_course', 'idx_enrollments_date', 'idx_courses_code_name')
GROUP BY TABLE_NAME, INDEX_NAME
ORDER BY TABLE_NAME, INDEX_NAME;

-- -------------------------------------------------------------
-- 6. Demonstration calls (read-only where possible)
--    A duplicate enrollment is used so the demo never changes data.
--    To test the success path manually (this DOES add a row):
--      CALL sp_EnrollStudent(1, 3, @msg);
--      SELECT @msg AS enrollment_result;
-- -------------------------------------------------------------
CALL sp_EnrollStudent(1, 1, @enroll_duplicate);
SELECT @enroll_duplicate AS duplicate_enrollment_result;

CALL sp_EnrollStudent(9999, 1, @enroll_missing);
SELECT @enroll_missing AS missing_student_result;

CALL sp_CalculateCourseGrade(1, @final_grade_1);
SELECT @final_grade_1 AS student1_final_grade;

CALL sp_CalculateCourseGrade(3, @final_grade_3);
SELECT @final_grade_3 AS student3_final_grade;

CALL sp_CalculateCourseGrade(9999, @final_grade_none);
SELECT @final_grade_none AS no_grades_final_grade;

SELECT * FROM student_transcript WHERE student_id = 1 ORDER BY course_code, assignment_type;
SELECT * FROM course_performance_analytics ORDER BY course_code;

-- =============================================================
-- LAB 6 (appended): DATA SECURITY, AUDIT TRAILS & BACKUP
-- =============================================================
-- =============================================================
-- LABORATORY EXERCISE 6 - DATA SECURITY, AUDIT TRAILS &
--                          ADVANCED APPLICATION FEATURES
-- Database: DB_Timon (MariaDB 10.11)
--
-- SAFE / RE-RUNNABLE:
--   * users are created with CREATE USER IF NOT EXISTS
--   * tables are created with CREATE TABLE IF NOT EXISTS
--   * triggers use CREATE OR REPLACE TRIGGER (no data is removed)
--   * procedures are refreshed with DROP/CREATE only after reporting
--     "already exists"; no academic data is deleted.
-- =============================================================

USE DB_Timon;

-- -------------------------------------------------------------
-- 0. Re-run status messages
-- -------------------------------------------------------------
SELECT IF(EXISTS(SELECT 1 FROM mysql.user WHERE User='dbt_admin' AND Host='localhost'),
          'DB user dbt_admin already exists - privileges refreshed',
          'DB user dbt_admin will be created') AS dbt_admin_status;
SELECT IF(EXISTS(SELECT 1 FROM mysql.user WHERE User='dbt_teacher' AND Host='localhost'),
          'DB user dbt_teacher already exists - privileges refreshed',
          'DB user dbt_teacher will be created') AS dbt_teacher_status;
SELECT IF(EXISTS(SELECT 1 FROM mysql.user WHERE User='dbt_student' AND Host='localhost'),
          'DB user dbt_student already exists - privileges refreshed',
          'DB user dbt_student will be created') AS dbt_student_status;

-- -------------------------------------------------------------
-- 1. Dedicated database users for application roles
--    Passwords are stored only in the encrypted connection-string
--    configuration used by the VB.NET client, never in source code.
-- -------------------------------------------------------------
CREATE USER IF NOT EXISTS 'dbt_admin'@'localhost'   IDENTIFIED BY 'DbTimon@Admin2026';
CREATE USER IF NOT EXISTS 'dbt_teacher'@'localhost' IDENTIFIED BY 'DbTimon@Teacher2026';
CREATE USER IF NOT EXISTS 'dbt_student'@'localhost' IDENTIFIED BY 'DbTimon@Student2026';

-- Admin: full application ownership (still no global server privileges).
-- SHOW VIEW and TRIGGER are required by mysqldump for a complete backup.
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE, CREATE TEMPORARY TABLES,
      SHOW VIEW, TRIGGER, LOCK TABLES
  ON DB_Timon.* TO 'dbt_admin'@'localhost';

-- Teacher: may manage grades and read the data needed for dashboards;
-- cannot change users, roles, audit logs or backup history.
GRANT SELECT ON DB_Timon.users TO 'dbt_teacher'@'localhost';
GRANT SELECT ON DB_Timon.roles TO 'dbt_teacher'@'localhost';
GRANT SELECT ON DB_Timon.students TO 'dbt_teacher'@'localhost';
GRANT SELECT ON DB_Timon.instructors TO 'dbt_teacher'@'localhost';
GRANT SELECT ON DB_Timon.courses TO 'dbt_teacher'@'localhost';
GRANT SELECT ON DB_Timon.enrollments TO 'dbt_teacher'@'localhost';
GRANT SELECT ON DB_Timon.assignment_types TO 'dbt_teacher'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON DB_Timon.grades TO 'dbt_teacher'@'localhost';
GRANT SELECT ON DB_Timon.teacher_course_overview TO 'dbt_teacher'@'localhost';
GRANT SELECT ON DB_Timon.student_grade_summary TO 'dbt_teacher'@'localhost';
GRANT SELECT ON DB_Timon.course_performance_analytics TO 'dbt_teacher'@'localhost';
GRANT EXECUTE ON PROCEDURE DB_Timon.sp_CalculateCourseGrade TO 'dbt_teacher'@'localhost';

-- Student: read-only access through curated views only.
GRANT SELECT ON DB_Timon.student_grade_summary TO 'dbt_student'@'localhost';
GRANT SELECT ON DB_Timon.student_transcript TO 'dbt_student'@'localhost';
GRANT SELECT ON DB_Timon.course_performance_analytics TO 'dbt_student'@'localhost';
GRANT EXECUTE ON PROCEDURE DB_Timon.sp_CalculateCourseGrade TO 'dbt_student'@'localhost';

FLUSH PRIVILEGES;

-- -------------------------------------------------------------
-- 1b. Optional e-mail column used by the validated user-registration form.
--     Added only when missing so existing accounts are preserved.
-- -------------------------------------------------------------
SELECT IF(EXISTS(SELECT 1 FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='users' AND COLUMN_NAME='email'),
          'users.email already exists',
          'users.email will be added') AS users_email_status;

SET @has_email = (SELECT COUNT(*) FROM information_schema.COLUMNS
                  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='users' AND COLUMN_NAME='email');
SET @add_email = IF(@has_email = 0,
    'ALTER TABLE users ADD COLUMN email VARCHAR(255) NULL AFTER password_hash',
    'SELECT 1');
PREPARE stmt_add_email FROM @add_email;
EXECUTE stmt_add_email;
DEALLOCATE PREPARE stmt_add_email;

-- -------------------------------------------------------------
-- 2. Audit log + backup history + login sessions
-- -------------------------------------------------------------
SELECT IF(EXISTS(SELECT 1 FROM information_schema.TABLES
                 WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='audit_log'),
          'Table audit_log already exists',
          'Table audit_log will be created') AS audit_log_status;

CREATE TABLE IF NOT EXISTS audit_log (
    audit_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    event_time    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    db_user       VARCHAR(100)    NOT NULL,
    app_user      VARCHAR(100)    NULL,
    table_name    VARCHAR(100)    NOT NULL,
    action_type   VARCHAR(20)     NOT NULL,
    record_id     VARCHAR(100)    NULL,
    old_values    TEXT            NULL,
    new_values    TEXT            NULL,
    host_name     VARCHAR(100)    NULL,
    PRIMARY KEY (audit_id),
    KEY idx_audit_time (event_time),
    KEY idx_audit_table_action (table_name, action_type),
    KEY idx_audit_app_user (app_user)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SELECT IF(EXISTS(SELECT 1 FROM information_schema.TABLES
                 WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='backup_history'),
          'Table backup_history already exists',
          'Table backup_history will be created') AS backup_history_status;

CREATE TABLE IF NOT EXISTS backup_history (
    backup_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    backup_time    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    backup_type    VARCHAR(30)    NOT NULL DEFAULT 'MANUAL',
    file_name      VARCHAR(255)   NOT NULL,
    status         VARCHAR(20)    NOT NULL DEFAULT 'SUCCESS',
    rows_backed_up INT            NOT NULL DEFAULT 0,
    initiated_by   VARCHAR(100)   NULL,
    notes          TEXT           NULL,
    PRIMARY KEY (backup_id),
    KEY idx_backup_time (backup_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SELECT IF(EXISTS(SELECT 1 FROM information_schema.TABLES
                 WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='user_sessions'),
          'Table user_sessions already exists',
          'Table user_sessions will be created') AS user_sessions_status;

CREATE TABLE IF NOT EXISTS user_sessions (
    session_id    CHAR(36)      NOT NULL,
    user_id       INT           NOT NULL,
    username      VARCHAR(100)  NOT NULL,
    login_time    DATETIME      NOT NULL,
    last_activity DATETIME      NOT NULL,
    logout_time   DATETIME      NULL,
    status        VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE',
    host_name     VARCHAR(100)  NULL,
    PRIMARY KEY (session_id),
    KEY idx_sessions_user_status (user_id, status),
    KEY idx_sessions_last_activity (last_activity),
    CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------
-- 3. Active-session view (used by the VB.NET status bar / audit form)
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW v_active_sessions AS
SELECT s.session_id,
       s.user_id,
       s.username,
       s.login_time,
       s.last_activity,
       TIMESTAMPDIFF(MINUTE, s.last_activity, NOW()) AS idle_minutes,
       CASE WHEN TIMESTAMPDIFF(MINUTE, s.last_activity, NOW()) >= 30
            THEN 'TIMED_OUT' ELSE 'ACTIVE' END AS session_state
FROM   user_sessions s
WHERE  s.status = 'ACTIVE';

-- Student-facing views: the dbt_student account never reads raw tables.
CREATE OR REPLACE VIEW student_own_profile AS
SELECT user_id, student_id, first_name, last_name
FROM   students;

CREATE OR REPLACE VIEW student_course_averages AS
SELECT g.student_id,
       c.course_code,
       c.course_name,
       ROUND(AVG(g.grade), 2) AS average_grade,
       COUNT(g.grade)        AS grades_recorded
FROM   grades g
JOIN   courses c ON c.course_id = g.course_id
GROUP BY g.student_id, c.course_code, c.course_name;

GRANT SELECT ON DB_Timon.student_own_profile    TO 'dbt_student'@'localhost';
GRANT SELECT ON DB_Timon.student_course_averages TO 'dbt_student'@'localhost';
FLUSH PRIVILEGES;

-- -------------------------------------------------------------
-- 4. Grade validation trigger (database-level business rule)
-- -------------------------------------------------------------
DELIMITER //

CREATE OR REPLACE TRIGGER tr_validate_grade_before_insert
BEFORE INSERT ON grades
FOR EACH ROW
BEGIN
    IF NEW.grade IS NOT NULL AND (NEW.grade < 0 OR NEW.grade > 100) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Grade must be between 0 and 100';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM enrollments e
                   WHERE e.student_id = NEW.student_id
                     AND e.course_id  = NEW.course_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student is not enrolled in this course';
    END IF;
END//

-- -------------------------------------------------------------
-- 5. Audit triggers for the grades table
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER tr_grades_after_insert
AFTER INSERT ON grades
FOR EACH ROW
BEGIN
    INSERT INTO audit_log
        (db_user, app_user, table_name, action_type, record_id, new_values, host_name)
    VALUES
        (USER(), @app_user, 'grades', 'INSERT',
         CONCAT(NEW.student_id, ':', NEW.course_id, ':', NEW.type_id),
         CONCAT('{"student_id":', NEW.student_id,
                ',"course_id":', NEW.course_id,
                ',"type_id":', NEW.type_id,
                ',"grade":', IFNULL(CAST(NEW.grade AS CHAR), 'null'), '}'),
         @@hostname);
END//

CREATE OR REPLACE TRIGGER tr_grades_after_update
AFTER UPDATE ON grades
FOR EACH ROW
BEGIN
    INSERT INTO audit_log
        (db_user, app_user, table_name, action_type, record_id, old_values, new_values, host_name)
    VALUES
        (USER(), @app_user, 'grades', 'UPDATE',
         CONCAT(NEW.student_id, ':', NEW.course_id, ':', NEW.type_id),
         CONCAT('{"grade":', IFNULL(CAST(OLD.grade AS CHAR), 'null'), '}'),
         CONCAT('{"grade":', IFNULL(CAST(NEW.grade AS CHAR), 'null'), '}'),
         @@hostname);
END//

CREATE OR REPLACE TRIGGER tr_grades_after_delete
AFTER DELETE ON grades
FOR EACH ROW
BEGIN
    INSERT INTO audit_log
        (db_user, app_user, table_name, action_type, record_id, old_values, host_name)
    VALUES
        (USER(), @app_user, 'grades', 'DELETE',
         CONCAT(OLD.student_id, ':', OLD.course_id, ':', OLD.type_id),
         CONCAT('{"student_id":', OLD.student_id,
                ',"course_id":', OLD.course_id,
                ',"type_id":', OLD.type_id,
                ',"grade":', IFNULL(CAST(OLD.grade AS CHAR), 'null'), '}'),
         @@hostname);
END//

CREATE OR REPLACE TRIGGER tr_validate_grade_before_update
BEFORE UPDATE ON grades
FOR EACH ROW
BEGIN
    IF NEW.grade IS NOT NULL AND (NEW.grade < 0 OR NEW.grade > 100) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Grade must be between 0 and 100';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM enrollments e
                   WHERE e.student_id = NEW.student_id
                     AND e.course_id  = NEW.course_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student is not enrolled in this course';
    END IF;
END//

DELIMITER ;

-- -------------------------------------------------------------
-- 6. Backup and maintenance procedures
-- -------------------------------------------------------------
SELECT IF(EXISTS(SELECT 1 FROM information_schema.ROUTINES
                 WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='sp_RecordBackup'),
          'Procedure sp_RecordBackup already exists - definition refreshed',
          'Procedure sp_RecordBackup will be created') AS sp_RecordBackup_status;

DROP PROCEDURE IF EXISTS sp_RecordBackup;
DELIMITER //
CREATE PROCEDURE sp_RecordBackup(
    IN  p_file_name   VARCHAR(255),
    IN  p_backup_type VARCHAR(30),
    IN  p_rows        INT,
    IN  p_status      VARCHAR(20),
    IN  p_initiated_by VARCHAR(100),
    IN  p_notes       TEXT,
    OUT p_backup_id   BIGINT UNSIGNED)
BEGIN
    INSERT INTO backup_history
        (backup_time, backup_type, file_name, status, rows_backed_up, initiated_by, notes)
    VALUES
        (NOW(), p_backup_type, p_file_name, p_status, p_rows, p_initiated_by, p_notes);
    SET p_backup_id = LAST_INSERT_ID();
END//
DELIMITER ;

SELECT IF(EXISTS(SELECT 1 FROM information_schema.ROUTINES
                 WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='sp_MaintenanceRoutine'),
          'Procedure sp_MaintenanceRoutine already exists - definition refreshed',
          'Procedure sp_MaintenanceRoutine will be created') AS sp_Maintenance_status;

DROP PROCEDURE IF EXISTS sp_MaintenanceRoutine;
DELIMITER //
CREATE PROCEDURE sp_MaintenanceRoutine()
BEGIN
    ANALYZE TABLE grades, enrollments, courses, audit_log;

    INSERT INTO audit_log
        (db_user, app_user, table_name, action_type, record_id, new_values, host_name)
    VALUES
        (USER(), @app_user, 'maintenance', 'ANALYZE', 'tables',
         '{"tables":"grades,enrollments,courses,audit_log"}', @@hostname);

    SELECT 'Maintenance completed: statistics refreshed' AS maintenance_result;
END//
DELIMITER ;

SELECT IF(EXISTS(SELECT 1 FROM information_schema.ROUTINES
                 WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='sp_TimeoutSessions'),
          'Procedure sp_TimeoutSessions already exists - definition refreshed',
          'Procedure sp_TimeoutSessions will be created') AS sp_TimeoutSessions_status;

DROP PROCEDURE IF EXISTS sp_TimeoutSessions;
DELIMITER //
CREATE PROCEDURE sp_TimeoutSessions(IN p_timeout_minutes INT)
BEGIN
    UPDATE user_sessions
       SET status = 'TIMED_OUT',
           logout_time = NOW()
     WHERE status = 'ACTIVE'
       AND TIMESTAMPDIFF(MINUTE, last_activity, NOW()) >= p_timeout_minutes;

    SELECT ROW_COUNT() AS timed_out_count;
END//
DELIMITER ;

-- -------------------------------------------------------------
-- 7. Verification
-- -------------------------------------------------------------
SELECT User, Host FROM mysql.user WHERE User LIKE 'dbt_%' ORDER BY User;

SELECT TABLE_NAME FROM information_schema.TABLES
WHERE TABLE_SCHEMA=DATABASE()
  AND TABLE_NAME IN ('audit_log','backup_history','user_sessions')
ORDER BY TABLE_NAME;

SELECT TRIGGER_NAME, EVENT_MANIPULATION, ACTION_TIMING
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA=DATABASE()
ORDER BY TRIGGER_NAME;

SELECT ROUTINE_NAME FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA=DATABASE()
  AND ROUTINE_NAME IN ('sp_RecordBackup','sp_MaintenanceRoutine','sp_TimeoutSessions')
ORDER BY ROUTINE_NAME;
