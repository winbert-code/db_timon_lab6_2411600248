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
