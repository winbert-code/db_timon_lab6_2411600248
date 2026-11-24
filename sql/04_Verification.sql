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
