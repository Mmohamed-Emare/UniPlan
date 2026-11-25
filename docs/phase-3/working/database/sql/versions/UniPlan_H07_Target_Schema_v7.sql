-- UniPlan H-07 target schema patch (SQLite)
-- Replace the legacy STUDY_TASK concept with independent PERSONAL_TASK and plan-based STUDY_SESSION.
-- STUDY_PLAN is an existing parent table in the full schema.
PRAGMA foreign_keys = ON;

-- Independent tasks owned directly by a student; no STUDY_PLAN dependency.
CREATE TABLE PERSONAL_TASK (
    task_id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL,
    course_id INTEGER,
    title TEXT NOT NULL CHECK (length(title) BETWEEN 1 AND 150),
    description TEXT,
    due_at TEXT,
    priority TEXT NOT NULL CHECK (priority IN ('LOW','MEDIUM','HIGH')),
    status TEXT NOT NULL DEFAULT 'TODO' CHECK (status IN ('TODO','IN_PROGRESS','COMPLETED')),
    estimated_minutes INTEGER CHECK (estimated_minutes IS NULL OR estimated_minutes > 0),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TEXT,
    FOREIGN KEY (student_id) REFERENCES STUDENT_PROFILE(user_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES COURSE(course_id),
    CHECK ((status = 'COMPLETED' AND completed_at IS NOT NULL) OR
           (status <> 'COMPLETED' AND completed_at IS NULL))
);
CREATE INDEX ix_personal_task_student_status ON PERSONAL_TASK(student_id, status);
CREATE INDEX ix_personal_task_due ON PERSONAL_TASK(student_id, due_at);

-- Time-blocked learning session organized by a STUDY_PLAN.
-- course_id and task_id are optional context links.
CREATE TABLE STUDY_SESSION (
    session_id INTEGER PRIMARY KEY,
    plan_id INTEGER NOT NULL,
    course_id INTEGER,
    task_id INTEGER,
    title TEXT NOT NULL CHECK (length(title) BETWEEN 1 AND 150),
    scheduled_start TEXT NOT NULL,
    scheduled_end TEXT NOT NULL,
    actual_start TEXT,
    actual_end TEXT,
    status TEXT NOT NULL DEFAULT 'PLANNED'
        CHECK (status IN ('PLANNED','IN_PROGRESS','COMPLETED','MISSED')),
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES STUDY_PLAN(plan_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES COURSE(course_id),
    FOREIGN KEY (task_id) REFERENCES PERSONAL_TASK(task_id),
    CHECK (scheduled_end > scheduled_start),
    CHECK (actual_end IS NULL OR (actual_start IS NOT NULL AND actual_end > actual_start)),
    CHECK (status <> 'COMPLETED' OR (actual_start IS NOT NULL AND actual_end IS NOT NULL))
);
CREATE INDEX ix_study_session_plan_start ON STUDY_SESSION(plan_id, scheduled_start);
CREATE INDEX ix_study_session_task ON STUDY_SESSION(task_id);

-- Service-layer integrity rules (must be enforced server-side):
-- 1) STUDY_SESSION.plan_id must belong to the authenticated student.
-- 2) If task_id is supplied, that PERSONAL_TASK must belong to the same student
--    who owns the referenced STUDY_PLAN. A task is not required for every session.
-- 3) If course_id is supplied, it must be a catalog course and may be checked
--    against task.course_id for consistency when both are present.
-- 4) Completing a PERSONAL_TASK sets completed_at; reopening clears it.
-- 5) Completing a STUDY_SESSION requires actual_start and actual_end.
-- 6) STUDY_TASK is superseded by PERSONAL_TASK + STUDY_SESSION. Migrate any
--    existing rows before dropping STUDY_TASK; do not discard user data.
