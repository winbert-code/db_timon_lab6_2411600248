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
