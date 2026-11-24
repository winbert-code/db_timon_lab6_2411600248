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
