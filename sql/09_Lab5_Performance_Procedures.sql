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
