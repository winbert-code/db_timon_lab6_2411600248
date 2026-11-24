# Laboratory Exercise 6 — Questions and Answers

Database: **DB_Timon** (MariaDB 10.11)

Objects implemented by `sql/10_Lab6_Security_Audit_Backup.sql`:

- dedicated database accounts `dbt_admin`, `dbt_teacher`, `dbt_student`
- `audit_log`, `backup_history`, `user_sessions` tables
- triggers `tr_validate_grade_before_insert`, `tr_validate_grade_before_update`, `tr_grades_after_insert`, `tr_grades_after_update`, `tr_grades_after_delete`
- procedures `sp_RecordBackup`, `sp_MaintenanceRoutine`, `sp_TimeoutSessions`
- view `v_active_sessions`

---

## 1. Describe two different scenarios where the audit trail system would be crucial for investigating issues or ensuring compliance. What specific information would you look for in each scenario?

### Scenario A — A disputed grade change

A student claims that their final grade was changed without permission after the grading deadline.

**Why the audit trail is crucial:** `tr_grades_after_update` writes one row per changed grade, so the investigation does not depend on memory or application logs. The database itself records who changed the mark and what the old and new values were.

**Information to look for in `audit_log`:**

```sql
SELECT audit_id, event_time, db_user, app_user, table_name,
       action_type, record_id, old_values, new_values, host_name
FROM   audit_log
WHERE  table_name = 'grades'
  AND  action_type = 'UPDATE'
  AND  record_id = '1:1:1'          -- student:course:type
ORDER BY event_time;
```

Key columns: `event_time` (exactly when), `app_user` (which application account was logged in), `db_user` (which role-based database account was used), `old_values`/`new_values` (e.g. `{"grade":92.00}` → `{"grade":93.00}`), and `host_name`. In the live demo, audit IDs 1–4 showed a DELETE, INSERT and two UPDATEs for record `1:1:1`, with the app user recorded as `admin`.

### Scenario B — Compliance / accountability for sensitive academic data

During an internal review, the institution must prove that only authorised staff accessed or modified academic records and that student data was not changed by an unauthorised account.

**Why the audit trail is crucial:** the combination of dedicated database users and audit rows gives a defensible chain of custody. `dbt_student` has only `SELECT` on curated views and is denied access to raw `users`; `dbt_teacher` can change `grades` but cannot touch `audit_log`, `users` or `backup_history`; `dbt_admin` owns the application data. Every grade mutation is recorded with both the DB account and the application user (`@app_user`).

**Information to look for:**

```sql
SELECT DATE(event_time) AS day, db_user, app_user,
       action_type, COUNT(*) AS changes
FROM   audit_log
GROUP BY DATE(event_time), db_user, app_user, action_type
ORDER BY day DESC;
```

Also cross-check `backup_history` (`initiated_by`, `backup_time`, `file_name`, `status`) and `user_sessions` (`login_time`, `logout_time`, `status`) to prove that the account was logged in at the time and that a verified backup existed before/after the change.

---

## 2. How does the `tr_validate_grade_before_insert` trigger improve data quality compared to implementing the same validation rules only in the VB.NET application?

A VB.NET-only check can be bypassed. The trigger is enforced **inside the database**, so every writer is subject to the same rules — the Windows Forms app, dbGate, phpMyAdmin, a scheduled job, an import script, or a future API.

`tr_validate_grade_before_insert` performs two checks before the row is written:

1. **Range check** — `grade` must be `NULL` or between `0.00` and `100.00`.
2. **Referential business rule** — the `(student_id, course_id)` pair must already exist in `enrollments`; a grade cannot be attached to a student who is not enrolled in that course.

Live verification produced:

```text
ERROR 1644 (45000): Grade must be between 0 and 100
ERROR 1644 (45000): Student is not enrolled in this course
```

Benefits over application-only validation:

- **Single source of truth:** the rule is defined once in the schema, not duplicated across forms.
- **Cannot be skipped:** direct SQL/import tools cannot bypass it. The existing `chk_grade_range` CHECK constraint is a second safety net, but the trigger gives a clear, application-specific message and also checks enrollment.
- **Atomic with the write:** if validation fails, the `SIGNAL SQLSTATE '45000'` aborts the statement; no partial or dirty row is stored.
- **Consistent errors:** the VB.NET layer can catch the same `45000` message and display it, but it is no longer the only guard.

The application should still validate early (better UX and fewer round-trips); the trigger is the authoritative final line of defence. `tr_validate_grade_before_update` applies the same rules to edits.

---

## 3. What are the potential performance implications of implementing comprehensive audit triggers on frequently modified tables like Grades, and what strategies could mitigate these impacts?

### Potential implications

- **Extra writes per DML statement:** every `INSERT`/`UPDATE`/`DELETE` on `grades` adds one `INSERT` into `audit_log`. Bulk imports or grade-sheet updates can double the write work and generate more redo/undo.
- **Lock contention:** `audit_log` becomes a shared hotspot. Many concurrent sessions inserting audit rows may contend on index pages, especially the right-most leaf of the primary key.
- **Synchronous execution:** triggers run in the same transaction as the statement. A slow audit insert slows the user's save operation; if the audit insert fails, the original change is rolled back too.
- **Storage growth:** `old_values`/`new_values` are `TEXT`. Continuous auditing on a large table can grow the audit table faster than the academic data itself.
- **Cascading cost in procedures:** any procedure or import loop that writes many grade rows pays the audit cost once per row, not once per batch.

### Mitigation strategies used or recommended here

1. **Index only what queries need.** `audit_log` has `idx_audit_time`, `idx_audit_table_action` and `idx_audit_app_user`, so the Audit Trail Viewer filters without full scans. Unnecessary indexes on audit columns would increase write cost.
2. **Keep the trigger body small.** The triggers only build compact JSON-like strings and insert one row; they do not call other procedures or scan large tables.
3. **Archive/partition old audit rows.** Move rows older than a retention period (e.g. 12 months) to an archive table or partition by `event_time`, then drop old partitions. `sp_MaintenanceRoutine` is the natural place to schedule this; this lab deliberately does not delete records.
4. **Audit selectively.** If a non-critical column (e.g. a display-only timestamp) changes often, use `UPDATE OF grade` or a `WHEN (OLD.grade <> NEW.grade)` guard so no-op updates do not create audit rows.
5. **Batch asynchronous auditing for very high volume.** For bulk imports, write a compact batch record to a staging table and flush it with a scheduled job instead of one synchronous row per grade.
6. **Use connection pooling and short transactions.** The VB.NET connection strings enable pooling and timeouts; short transactions reduce how long audit/index locks are held.
7. **Monitor with `EXPLAIN` and slow query log.** Review `audit_log` filters and maintenance routines as data grows; the same approach used for Lab 5 indexes applies here.

The lab keeps synchronous, database-enforced auditing because correctness and compliance are the priority at the current data size; the mitigations above are the scale-up path.
