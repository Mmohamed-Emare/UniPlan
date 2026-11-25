-- UniPlan C-02: Four-role authentication and course-scoped staff authorization
-- Design patch only. Reconcile table/column names with the final approved schema before execution.
PRAGMA foreign_keys = ON;

-- USER.role must support the four roles specified in the SRS.
-- For a new database, define it as:
-- role TEXT NOT NULL CHECK (role IN ('STUDENT','TA','INSTRUCTOR','ADMIN'))
-- For an existing SQLite database, role CHECK changes require a controlled USER table rebuild;
-- SQLite does not provide a direct ALTER COLUMN CHECK operation.

CREATE TABLE IF NOT EXISTS COURSE_STAFF_ASSIGNMENT (
    staff_assignment_id INTEGER PRIMARY KEY,
    staff_user_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    assigned_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    assignment_status TEXT NOT NULL DEFAULT 'ACTIVE'
        CHECK (assignment_status IN ('ACTIVE','INACTIVE')),
    CONSTRAINT fk_staff_user FOREIGN KEY (staff_user_id) REFERENCES USER(user_id),
    CONSTRAINT fk_staff_course FOREIGN KEY (course_id) REFERENCES COURSE(course_id),
    CONSTRAINT uq_staff_course UNIQUE (staff_user_id, course_id)
);

CREATE INDEX IF NOT EXISTS ix_staff_assignment_course_status
    ON COURSE_STAFF_ASSIGNMENT(course_id, assignment_status);

-- Add created_by to ASSIGNMENT in the canonical schema definition:
-- created_by INTEGER NOT NULL REFERENCES USER(user_id)
-- Existing rows need a valid migration/backfill before NOT NULL can be enforced.

-- Authorization query pattern for TA/Instructor actions:
-- SELECT 1
-- FROM COURSE_STAFF_ASSIGNMENT csa
-- JOIN USER u ON u.user_id = csa.staff_user_id
-- WHERE csa.staff_user_id = ?
--   AND csa.course_id = ?
--   AND csa.assignment_status = 'ACTIVE'
--   AND u.role IN ('TA','INSTRUCTOR');
-- The service layer must also verify that the assignment's section belongs to this course.

-- Never trust a role supplied by the browser. Use USER.role from the authenticated session.

-- Optional database-level guard: reject mappings for non-teaching roles.
CREATE TRIGGER IF NOT EXISTS trg_course_staff_role_insert
BEFORE INSERT ON COURSE_STAFF_ASSIGNMENT
FOR EACH ROW
WHEN COALESCE((SELECT role FROM USER WHERE user_id = NEW.staff_user_id), '') NOT IN ('TA','INSTRUCTOR')
BEGIN
    SELECT RAISE(ABORT, 'Only TA or INSTRUCTOR accounts may receive course assignments');
END;

CREATE TRIGGER IF NOT EXISTS trg_course_staff_role_update
BEFORE UPDATE OF staff_user_id ON COURSE_STAFF_ASSIGNMENT
FOR EACH ROW
WHEN COALESCE((SELECT role FROM USER WHERE user_id = NEW.staff_user_id), '') NOT IN ('TA','INSTRUCTOR')
BEGIN
    SELECT RAISE(ABORT, 'Only TA or INSTRUCTOR accounts may receive course assignments');
END;

-- Optional guard: prevent changing a mapped staff account to a non-staff role
-- until its active staff-course mappings have been deactivated or removed.
CREATE TRIGGER IF NOT EXISTS trg_user_role_change_with_active_staff_mapping
BEFORE UPDATE OF role ON USER
FOR EACH ROW
WHEN NEW.role NOT IN ('TA','INSTRUCTOR')
 AND EXISTS (
     SELECT 1 FROM COURSE_STAFF_ASSIGNMENT csa
     WHERE csa.staff_user_id = OLD.user_id
       AND csa.assignment_status = 'ACTIVE'
 )
BEGIN
    SELECT RAISE(ABORT, 'Deactivate staff-course assignments before changing this account role');
END;

-- Optional guard: only a currently assigned TA/Instructor may create a brief
-- for a section whose parent course matches the active staff-course mapping.
CREATE TRIGGER IF NOT EXISTS trg_assignment_creator_course_scope
BEFORE INSERT ON ASSIGNMENT
FOR EACH ROW
WHEN NOT EXISTS (
    SELECT 1
    FROM SECTION s
    JOIN COURSE_STAFF_ASSIGNMENT csa ON csa.course_id = s.course_id
    JOIN USER u ON u.user_id = csa.staff_user_id
    WHERE s.section_id = NEW.section_id
      AND csa.staff_user_id = NEW.created_by
      AND csa.assignment_status = 'ACTIVE'
      AND u.role IN ('TA','INSTRUCTOR')
)
BEGIN
    SELECT RAISE(ABORT, 'Assignment creator is not authorized for this course');
END;
