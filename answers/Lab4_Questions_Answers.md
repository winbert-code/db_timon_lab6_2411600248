# Laboratory Exercise 4 — Questions and Answers

Database: **DB_Timon** (MariaDB 10.11)

Objects implemented by `sql/08_Lab4_Gradebook.sql`:
`assignment_types`, `grades`, `student_grade_summary`, `teacher_course_overview`.

---

## 1. The Grades table uses a composite primary key (student_id, course_id, type_id). What specific business rule does this enforce, and why is it critical for a gradebook system?

### The rule

The composite (compound) primary key makes the combination of all three columns unique:

```sql
PRIMARY KEY (student_id, course_id, type_id)
```

It enforces: **a student can have at most ONE grade record for a given assignment type in a given course.** In other words, a grade is identified by *who* earned it, *in which course*, and *for which assessment category*.

The table therefore models a **ternary (three-way) relationship**:

```
students  ──┐
courses   ──┼──>  grades  <── assignment_types
             │
(one row per valid student × course × type combination)
```

Examples:

| student_id | course_id | type_id | Result |
|---|---|---|---|
| 1 | 1 | 1 (Homework) | allowed |
| 1 | 1 | 1 (Homework) again | **rejected** — duplicate primary key |
| 1 | 1 | 2 (Quiz) | allowed — a different type |
| 1 | 2 | 1 (Homework) | allowed — a different course |
| 2 | 1 | 1 (Homework) | allowed — a different student |

### Why it is critical

1. **Prevents duplicate / conflicting marks.** Without the composite key, a teacher (or a buggy form submission) could insert two "Midterm" grades for the same student in CS101. A dashboard would then show two different values, averages would double-count the assessment, and nobody could tell which one was official.

2. **Guarantees a stable identity for updates.** VB.NET can use the three columns as the key in an `INSERT ... ON DUPLICATE KEY UPDATE` (or `SELECT` then `UPDATE`) so that re-entering a grade *updates* the existing mark instead of adding another row. This is the standard "upsert" pattern for a gradebook.

3. **Matches the business meaning of a grade.** A grade is not identified by a surrogate number that users never see; it is identified by its three natural dimensions. The key makes that rule a database invariant rather than a convention that every application must remember to follow.

4. **Enables the weighting scheme of Lab 5.** `sp_CalculateCourseGrade` joins each grade to `assignment_types.default_weight`. Because one row exists per student/course/type, each weight is applied exactly once. Duplicates would silently inflate the weighted average.

5. **Works together with the other constraints.**
   - The three foreign keys ensure the referenced student, course and type really exist.
   - `chk_grade_range` ensures each value is a valid mark (or `NULL` for "not yet graded").
   - The nullable `grade` column allows the row to exist as a placeholder before a mark is entered, while the key still prevents a second placeholder from being created.

> Note the difference from `enrollments`: `UNIQUE (student_id, course_id)` prevents duplicate *enrollments*. The grades' composite PK additionally includes `type_id`, because one enrolled student legitimately has several graded assessment types in the same course.

---

## 2. Explain the purpose of the CHECK constraint chk_grade_range in the Grades table. What would happen if someone tried to insert a grade of 105 or -10?

### The constraint

```sql
CONSTRAINT chk_grade_range
    CHECK (grade IS NULL OR (grade >= 0.00 AND grade <= 100.00))
```

(MariaDB also accepts `grade BETWEEN 0 AND 100`; either form expresses the same domain.)

### Purpose

`CHECK` constraints enforce **domain integrity** — they restrict the values a column may accept. Here the business rule is "a grade is a percentage from 0 to 100, or it is not yet recorded". The constraint:

- rejects typos, bad imports and malicious values **at the database level**, no matter which client sent them (VB.NET form, dbGate, a script, or an API);
- allows `NULL` explicitly, which is important: a teacher may create a grade row (for example, to mark that a quiz is pending) before entering the score;
- protects every downstream calculation — `AVG`, `MIN`, `MAX` in the reporting views and the weighted `sp_CalculateCourseGrade` result would be meaningless if values such as 105 or -10 were stored;
- complements `chk_default_weight_range` on `assignment_types.default_weight`, which likewise restricts weights to 0–100.

MariaDB enforces `CHECK` constraints from version 10.2.1 onward, so on this server (10.11.16) the rule is actively applied, not merely parsed.

### What happens with 105 or -10

Both values violate the constraint:

| Attempted statement | Outcome |
|---|---|
| `INSERT INTO grades (...) VALUES (..., 105.00)` | Statement fails with a check-constraint violation error (e.g. `Check constraint 'chk_grade_range' is violated.`); no row is inserted. |
| `UPDATE grades SET grade = -10 WHERE ...` | Statement fails the same way; the existing row keeps its old value. |
| `INSERT ... grade = NULL` | **Succeeds** — `NULL` means "no grade recorded yet". |

The database rejects the whole statement, so the application receives an error and the teacher can correct the value. This is preferable to validating only in VB.NET, because a second application or a manual SQL edit could otherwise bypass the form-level check.

---

## 3. How does using a Database View improve the application compared to writing the full SQL query directly in the VB.NET code?

A view is a stored, named `SELECT` — a virtual table. In this project the two Lab 4 views are:

- `student_grade_summary` — students, grades, courses and assignment types joined for the Student dashboard.
- `teacher_course_overview` — courses, instructors, grades and assignment types grouped by course and type, including `user_id` so the teacher's dashboard can filter by the logged-in user.

### Benefits over embedding the SQL in VB.NET

1. **Simplification of application code.** The complex four-table join and the `GROUP BY`/`AVG` aggregation live in the database. The VB code becomes:

   ```vb
   SELECT * FROM teacher_course_overview WHERE user_id = @loggedInUserId
   ```

   instead of repeating a long join in every form. The data grid is bound to the view just as it would be to a table.

2. **One authoritative definition (consistency).** If the schema changes (a column is renamed, a new join is needed, a filter is added), the view is changed once with `CREATE OR REPLACE VIEW`. With hard-coded SQL, every form that contains a copy of the query must be located and edited — easily missed, which produces dashboards showing different numbers.

3. **Security and least privilege.** A view exposes exactly the columns needed by a role. There is no need to grant a student account direct access to all columns of `students`, `enrollments` or `instructors`. Row-level filtering is simple: the Student dashboard appends `WHERE student_id = @id`, and the Teacher dashboard appends `WHERE user_id = @userId`. Sensitive columns (password hashes, for example) are never part of the view.

4. **Maintainability and separation of concerns.** Database people can tune the query, add indexes and change joins without recompiling the VB.NET application, as long as the view's column names stay the same. The user's specified column names (`student_id`, `student_name`, `course_code`, `course_name`, `type_name`, `grade`, `date_recorded`, etc.) form a stable contract for the UI.

5. **Performance transparency.** MariaDB's optimizer merges a simple view into the outer query, so filtering the view can still use indexes on the base tables (e.g. `idx_grades_student_course`). The DBA can also add indexes or replace a view with a tuned query without touching VB code. No result set is physically duplicated (unlike a temporary table).

6. **Reusability.** The same view feeds the dashboard, a report and an export feature. Different filtering/sorting is done with `WHERE`/`ORDER BY` on the view.

7. **Reduced injection risk.** Because the SQL structure is fixed in the database, the application only has to supply parameter values for the `WHERE` clause; it does not build join strings from user input.

### Important caveat

Views are read-only for most dashboards here. `teacher_course_overview` contains `GROUP BY` and aggregates, so it cannot be updated directly. Grade entry/update must still be performed on the base `grades` table (e.g. `INSERT ... ON DUPLICATE KEY UPDATE`), using the composite key described in Question 1. Simple views can be updatable, but relying on that for a grouped report would be incorrect.
