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
