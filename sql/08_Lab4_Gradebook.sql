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
