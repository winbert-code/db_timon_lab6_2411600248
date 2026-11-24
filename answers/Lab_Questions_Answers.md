# Answers to Laboratory Exercise Questions

Database: **DB_Timon**

---

## Laboratory Exercise 1 — Database Creation & Foundational DDL

### 1. What is the purpose of the `AUTO_INCREMENT` attribute?

`AUTO_INCREMENT` automatically generates the next unique numeric value for a column when a new row is inserted without an explicit value for that column. It is normally used on an integer primary key (for example `student_id`).

Its purposes are:

- **Unique identification:** every record gets a distinct ID without the user or application having to invent one.
- **Convenience:** the application can omit the ID column in `INSERT` statements; MySQL/MariaDB supplies it.
- **Safety under concurrency:** the server generates values, so two users inserting at the same time cannot receive the same ID.
- **Stable references:** other tables can use the generated ID as a foreign key.

The column must be indexed (a primary key is typical), the values are sequential, and a deleted number is not reused.

### 2. Why is `VARCHAR` more suitable than `CHAR` for names and email addresses?

`CHAR(n)` is **fixed-length**: it always reserves `n` characters and pads shorter values with spaces. `VARCHAR(n)` is **variable-length**: it stores only the characters actually used, plus a small length prefix.

Names and email addresses vary greatly in length ("Jo" versus "Christopher", "a@b.com" versus "first.last@department.university.edu"). With `VARCHAR`, short values use little space and long values are still allowed; with `CHAR(255)`, every short value would waste storage and require trimming. `CHAR` is more appropriate for genuinely fixed-length data such as country codes or `CHAR(2)` state abbreviations.

### 3. What potential issue is there with using only a `student_id` as a primary key from a user perspective?

`student_id` is a **surrogate key**: it is meaningful to the database but meaningless to people. A user cannot look at "17" and know which student it identifies, cannot choose or remember it, and cannot use it to look up a record without first discovering the generated value. It may also expose enumeration/privacy concerns if shown in URLs.

In practice, keep `student_id` as the internal primary key but also store a natural, user-facing identifier such as a unique `email` or `username`, and let users search/log in with that.

---

## Laboratory Exercise 2 — Advanced Table Design & Relationships

### 1. What is the purpose of the `Enrollments` table?

`Enrollments` is a **junction (associative) table** that resolves the many-to-many relationship between `Students` and `Courses`. A student can take many courses and a course can have many students; a relational database cannot store that directly with two foreign-key columns, so the M:N relationship is split into two one-to-many relationships:

- `Students` 1 → M `Enrollments`
- `Courses` 1 → M `Enrollments`

It also stores data that belongs to the *relationship itself*, such as `enrollment_date` (and later grades or status). The `UNIQUE (student_id, course_id)` rule prevents a student from being enrolled in the same course twice.

### 2. What does the `FOREIGN KEY` constraint do if you try to delete a Student who is referenced in the `Enrollments` table?

It protects **referential integrity**: a row in `Enrollments` must always point to an existing student. With the default action (`RESTRICT`/`NO ACTION`), the `DELETE` is rejected with a foreign-key constraint error while enrollment rows still reference that student. You must delete or reassign the enrollments first.

If the constraint is declared with `ON DELETE CASCADE`, the database instead deletes the referencing enrollment rows automatically. If it is declared `ON DELETE SET NULL`, the child column is set to `NULL` (only possible when the column is nullable). In this project, the enrollment foreign keys use the default restrictive behaviour; only `courses.instructor_id` uses `ON DELETE SET NULL` because a course is allowed to be unassigned.

### 3. How would you design a table to store a student's different phone numbers? Why?

Create a separate one-to-many table instead of adding `phone1`, `phone2`, ... columns to `Students`:

```
student_phones (
    phone_id     INT PK AUTO_INCREMENT,
    student_id   INT NOT NULL FK -> students(student_id),
    phone_type   VARCHAR(20) NOT NULL,   -- Cell, Home, Work, Guardian...
    phone_number VARCHAR(30) NOT NULL,
    UNIQUE (student_id, phone_type, phone_number)
)
```

Why:

- It supports **any number** of phone numbers per student, not a fixed count.
- It avoids repeating groups, NULL-filled columns, and update anomalies (3rd normal form).
- `phone_type` gives each number meaning, and the composite UNIQUE rule prevents duplicates.
- Deleting a student can cleanly cascade to their phone rows.

---

## Laboratory Exercise 3 — Advanced Table Design, Relationships & User Management

### 1. What does the `FOREIGN KEY` constraint on the `instructor_id` column in the `Courses` table prevent?

It prevents a course from being assigned to an instructor who does not exist in the `Instructors` table. Any `INSERT` or `UPDATE` of `courses.instructor_id` must match an existing `instructors.instructor_id`; otherwise the statement fails with a foreign-key error.

It also restricts deletion/modification of an instructor that is still referenced: you cannot delete that instructor while courses point to it (here, `ON DELETE SET NULL` is used instead, which safely unassigns those courses). `NULL` is allowed so a course can exist before an instructor is assigned.

### 2. How does the `UNIQUE` constraint on the `user_id` field in the `Instructors` table enforce business logic?

`user_id` is already a foreign key to `Users`, so it guarantees the account exists. Adding `UNIQUE` guarantees that the same account can appear in `Instructors` **at most once**. That turns the relationship into **one-to-one**: one login account ↔ one instructor profile.

The business rule enforced is "one teacher account has exactly one instructor profile, and two teacher accounts cannot share a profile." Without `UNIQUE`, the same user could be linked to several instructor rows and the application would not know which profile to show. The same pattern is used in `Students`.

### 3. Describe the process an Admin would use to add a new Teacher to the system in your VB.NET application.

1. The Admin logs in. The app queries `Users`, verifies the PBKDF2 hash, reads `role_id`, and opens `AdminForm` only because `role_id = 1` (Admin).
2. On the **Add Teacher** tab, the Admin enters username, password, first name, last name, and department, then clicks **Create Teacher Account**.
3. The app validates the fields and generates a new random salted PBKDF2 hash for the password. The plain-text password is never stored.
4. Inside a single database **transaction**:
   - `INSERT` into `Users` with `role_id = 2` (Teacher) and the hash; read back `LAST_INSERT_ID()` to obtain the new `user_id`.
   - `INSERT` into `Instructors` using that `user_id` plus the profile details.
   - `COMMIT`. If either insert fails, `ROLLBACK` so no half-created account remains.
5. The lists refresh, the Admin sees the new user and instructor, and the new teacher can log in with the chosen credentials. `Reset Password` generates a fresh salted hash for an existing user.
