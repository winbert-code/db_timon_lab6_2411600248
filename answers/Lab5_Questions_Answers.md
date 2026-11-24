# Laboratory Exercise 5 — Questions and Answers

Database: **DB_Timon** (MariaDB 10.11)

Objects implemented by `sql/09_Lab5_Performance_Procedures.sql`:
indexes `idx_grades_student_course`, `idx_enrollments_date`, `idx_courses_code_name`;
procedures `sp_EnrollStudent`, `sp_CalculateCourseGrade`;
views `student_transcript`, `course_performance_analytics`.

---

## 1. Explain how the composite index idx_grades_student_course improves query performance for grade lookups. What types of queries would benefit most from this index?

### What the index is

```sql
CREATE INDEX idx_grades_student_course ON grades (student_id, course_id);
```

A composite (multi-column) index stores a B-tree whose keys are `(student_id, course_id)` in sorted order, with each key pointing back to the matching `grades` row. MariaDB can use the index's **leftmost prefix** — that is, `student_id` alone, or `student_id` together with `course_id`.

Note that the composite primary key of `grades` is `(student_id, course_id, type_id)`, whose first two columns are exactly the same. The PK therefore already supplies a usable leftmost prefix, so this explicit index is partly redundant for pure lookup speed. It is still useful as a clearly named, focused access path for the dashboard/report queries, gives the optimizer an exact match for two-column predicates and can serve as a narrower covering index for queries that only need those two columns. The trade-off is one extra index to maintain on every `INSERT`/`UPDATE`/`DELETE`.

### How it helps

Without a suitable index, MariaDB must scan the entire `grades` table (a full table scan) to find a student's marks. With the index it performs a range/ref lookup: it descends the B-tree directly to the first entry for the requested student and reads only the matching leaf pages. Cost grows roughly with the number of matching rows rather than with the total number of grades. The benefit increases as the table grows from hundreds to millions of rows.

### Queries that benefit most

1. **Student dashboard / transcript lookups**

   ```sql
   SELECT * FROM grades WHERE student_id = 3;
   SELECT * FROM student_grade_summary WHERE student_id = 3;
   ```

2. **Per-course grade lists for one student** — an exact match on both key columns:

   ```sql
   SELECT * FROM grades WHERE student_id = 3 AND course_id = 2;
   ```

   This is the lookup pattern used when the teacher opens one student's grades for one course, and by `sp_CalculateCourseGrade` when extended with a course parameter.

3. **Joins from `students` to `grades`** (`g.student_id = s.student_id`), which back `student_grade_summary`, and joins from a small set of students to their grade rows.

4. **`GROUP BY` / `ORDER BY student_id, course_id`** and other reports that need grades grouped or sorted in that column order — the index already stores the rows in that order, so a costly filesort can be avoided.

5. **Range queries on the leading column**, e.g. `WHERE student_id BETWEEN 10 AND 20`.

### Queries that do NOT benefit

- `WHERE course_id = 2` by itself — `course_id` is not the leftmost column (a separate index on `course_id` would be needed; the PK's third column `type_id` and other indexes do not help either).
- `WHERE type_id = 1` or `WHERE grade > 90` on their own.
- Leading-column expressions that prevent index use, e.g. `WHERE student_id + 0 = 3` or wrapping the column in a function.
- Very small tables, where a full scan is cheaper than an index lookup.

### Related indexes in this lab

- `idx_enrollments_date (enrollment_date)` speeds up date-range searches and "recent enrollments" reports.
- `idx_courses_code_name (course_code, course_name)` speeds up course-code searches and auto-complete; `course_code` is also already `UNIQUE`, so this composite index additionally covers queries that select the name along with the code.

Indexes improve reads but add write overhead, so only frequently queried columns should be indexed. `EXPLAIN` should be used to confirm that the optimizer actually chooses the index.

---

## 2. How does transaction handling in sp_EnrollStudent ensure data integrity during the enrollment process? Describe a scenario where this prevents data inconsistency.

### How the procedure works

`sp_EnrollStudent(p_student_id, p_course_id, OUT p_message)` wraps the whole operation in an InnoDB transaction:

1. `START TRANSACTION` begins an atomic unit of work.
2. It checks that the student exists, the course exists, and the pair is not already enrolled (`SELECT COUNT(*)` on `students`, `courses`, `enrollments`).
3. On any failed validation it issues `ROLLBACK` and sets an `Error: ...` message — nothing was written, but rolling back also releases locks cleanly.
4. Only if all checks pass does it `INSERT INTO enrollments (student_id, course_id)`.
5. `COMMIT` makes the insert permanent **only then**, and the message becomes `Success: Student enrolled successfully`.
6. An `EXIT HANDLER FOR SQLEXCEPTION` catches any SQL error at any point (foreign-key failure, duplicate-key error, deadlock, disk error, etc.), executes `ROLLBACK`, uses `GET DIAGNOSTICS CONDITION 1 ... MESSAGE_TEXT` to read the database error and returns `Error: <message>` to the caller.

### Integrity guarantees

- **Atomicity — all or nothing.** Either the enrollment is committed completely or no trace of it remains. There is no state where half of the operation succeeded.
- **Consistency.** The checks run inside the same transaction, so under InnoDB's default `REPEATABLE READ` isolation they see a consistent snapshot. The foreign keys and `UNIQUE (student_id, course_id)` constraint are still enforced by the database as a final safety net.
- **Isolation / concurrency.** InnoDB row and gap locks prevent two concurrent calls from both passing the duplicate check and inserting the same pair. If one wins and the other hits the unique constraint, the loser's exception handler rolls back and returns an `Error:` message instead of creating a duplicate.
- **Error propagation.** The OUT parameter lets the VB.NET admin form display the exact reason for failure instead of showing an unhandled exception or silently assuming success.

### Scenario: double-click / concurrent enrollment

A registrar clicks **Enroll** twice quickly, or two staff members enroll student 1 in CS201 at the same time.

**Without a transaction:** the first request inserts the row; the second request might still read stale data, attempt its own insert, throw an unhandled duplicate-key error, and — if the application performed additional steps (e.g. writing an audit row or updating a course counter) — could leave the audit row or counter updated while the enrollment itself failed. The data would be inconsistent.

**With this procedure:** the second call either sees the existing pair during its validation (`ROLLBACK`, `Error: Student already enrolled in this course`) or waits and then fails on the unique constraint; its exception handler rolls back everything and returns an `Error:` message. The database ends with exactly one enrollment row, no orphan audit rows, and the UI shows a clear message. A similar argument applies if the insert itself succeeds but a later statement in an extended procedure fails — the handler rolls the insert back.

Demo results from the live database confirm the messages:

- `CALL sp_EnrollStudent(1, 1, @m)` → `Error: Student already enrolled in this course`
- `CALL sp_EnrollStudent(9999, 1, @m)` → `Error: Student not found`
- `CALL sp_EnrollStudent(1, 3, @m)` → `Success: Student enrolled successfully`
- `CALL sp_CalculateCourseGrade(1, @g)` → `85.08` (weighted average); `9999` → `0.00`

---

## 3. The CoursePerformanceAnalytics view uses multiple JOIN operations and aggregate functions. How could this view support institutional decision-making, and what potential performance considerations should be addressed?

### The view

`course_performance_analytics` returns one row per course with:

`course_id, course_code, course_name, instructor_name, enrolled_students, grades_submitted, average_grade, minimum_grade, maximum_grade`.

Enrollment counts and grade statistics are aggregated in **separate derived tables** before being joined to `courses`/`instructors`. That is deliberate: joining raw `enrollments` and `grades` would multiply rows (each grade paired with every enrollment in the course), inflating counts — e.g. 12 grades × 3 students would be reported as 36 grades. The derived-table design reports 12.

### How it supports institutional decision-making

1. **Curriculum and section health.** Low `average_grade` or a high gap between `enrolled_students` and `grades_submitted` can reveal a course where students are falling behind or dropping out, triggering tutoring or schedule changes.

2. **Instructor and course comparison.** Because `instructor_name` and all three measures are in one result, administrators can compare sections taught by different instructors and identify where teaching practices or assessment difficulty should be reviewed. This should be done carefully and in context — averages alone are not a fair evaluation.

3. **Assessment quality.** `minimum_grade`, `maximum_grade` and `average_grade` together show spread. A very wide range may indicate inconsistent grading or wildly differing student preparation; a very narrow high range may indicate an unchallenging assessment.

4. **Resource allocation.** Courses with many enrolled students and low performance can be prioritized for lab assistants, review sessions or smaller sections.

5. **Reporting and trends.** The view is a ready-made data source for the VB.NET `ReportsForm`, CSV/PDF export and dashboards. Adding a date dimension (term/year or `enrollment_date`) would allow term-to-term trend analysis and accreditation reports. Filtering can be done in the outer query (`WHERE course_code = ...`, `WHERE instructor_name = ...`, date ranges) without changing the view.

### Performance considerations

1. **Avoid row multiplication.** As described above, aggregate each fact table separately (or use `COUNT(DISTINCT ...)`) before joining. This is both a correctness and a performance issue.

2. **Indexes on join/filter columns.** Ensure indexes exist on `courses.course_id` (PK), `enrollments.course_id` and `student_id` (FKs/unique), `grades.course_id` (covered by `idx_grades_student_course`'s second position only when combined with `student_id` — a dedicated `course_id` index is advisable if course-wide grade scans are common), and `instructors.instructor_id` (PK). The Lab 5 indexes `idx_enrollments_date`, `idx_courses_code_name` and `idx_grades_student_course` help the corresponding search patterns.

3. **Cost of GROUP BY and aggregates.** `AVG`/`MIN`/`MAX` over growing `grades` and `enrollments` tables require grouping and sorting. A plain view does not store results; the aggregation is executed each time it is queried. Use `EXPLAIN` to check for full table scans and temporary tables/filesorts.

4. **Filter pushdown and selective queries.** MariaDB usually merges a view's definition into the outer query, so `WHERE c.course_id = 5` can reduce rows early. Encourage the VB report form to filter by course/term instead of repeatedly pulling the whole view. Avoid applying functions to indexed columns in the `WHERE` clause.

5. **Scaling strategy.** For very large datasets, consider a pre-aggregated summary table refreshed by a scheduled job, or indexed/materialized summary tables, rather than recomputing the analytics on every screen refresh. Cache results in the application for read-heavy dashboards.

6. **Write overhead.** Every additional index speeds these reads but slows `INSERT`/`UPDATE` on grades and enrollments; balance the two and review index usage periodically.

7. **Correctness of counts.** Decide explicitly whether `grades_submitted` counts non-NULL marks only (current implementation via `COUNT(grade)`) and whether ungraded placeholder rows should appear; document the choice so reports are interpreted consistently.
