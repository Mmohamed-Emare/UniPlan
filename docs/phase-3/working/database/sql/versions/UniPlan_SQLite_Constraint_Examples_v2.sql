-- EMARA UNIVERSITY — ME Group | UniPlan
-- SQLite constraint examples for the v2 logical data model.
-- This is an implementation supplement, not a complete schema-migration script.
-- Review names against the approved SRS/Class Diagram before production use.

-- IMPORTANT: execute this when opening EVERY SQLite connection,
-- before beginning a transaction. SQLite foreign-key enforcement is connection-scoped.
PRAGMA foreign_keys = ON;

-- 1) Fixed GPA lookup table.
-- Actual letter labels, score intervals, and grade points must come from the approved policy.
CREATE TABLE IF NOT EXISTS GPA_SCALE (
    grade_scale_id INTEGER PRIMARY KEY,
    letter_grade   TEXT NOT NULL UNIQUE CHECK (length(letter_grade) <= 5),
    min_score      REAL NOT NULL CHECK (min_score >= 0),
    max_score      REAL NOT NULL CHECK (max_score >= min_score),
    grade_points   REAL NOT NULL CHECK (grade_points >= 0)
);

-- Application validation must also ensure that GPA_SCALE score intervals do not overlap
-- and that each accepted numeric score maps to exactly one row.

-- 2) ENROLLMENT grading fields (incorporate these into the full ENROLLMENT table definition).
-- Keep the original composite PK (student_id, section_id), enrolled_at and status fields.
-- grade_scale_id is NULL until a final grade is recorded.
-- For numeric input: store final_score AND the matching grade_scale_id.
-- For letter input: store grade_scale_id only and leave final_score NULL.
-- For no final grade: both are NULL.
-- Constraint: CHECK (final_score IS NULL OR grade_scale_id IS NOT NULL)
-- Foreign key: FOREIGN KEY (grade_scale_id) REFERENCES GPA_SCALE(grade_scale_id)

-- 3) Current assignment submission record.
-- Incorporate these fields and constraints into ASSIGNMENT_SUBMISSION.
CREATE TABLE IF NOT EXISTS ASSIGNMENT_SUBMISSION (
    submission_id   INTEGER PRIMARY KEY,
    assignment_id   INTEGER NOT NULL REFERENCES ASSIGNMENT(assignment_id),
    student_id      INTEGER NOT NULL REFERENCES STUDENT_PROFILE(user_id),
    submission_text TEXT,
    file_path       TEXT,
    status          TEXT NOT NULL DEFAULT 'DRAFT'
                    CHECK (status IN ('DRAFT', 'SUBMITTED', 'GRADED')),
    submitted_at    TEXT,
    score_awarded   REAL CHECK (score_awarded IS NULL OR score_awarded >= 0),
    feedback        TEXT,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL,
    UNIQUE (assignment_id, student_id),
    CHECK (
        status = 'DRAFT'
        OR (submitted_at IS NOT NULL
            AND (submission_text IS NOT NULL OR file_path IS NOT NULL))
    ),
    CHECK (status <> 'GRADED' OR score_awarded IS NOT NULL)
);

-- The current design stores the latest submission for each student/assignment.
-- Resubmission updates this record. Add a submission-version table only if the SRS requires history.
-- Validate score_awarded <= ASSIGNMENT.max_score in application logic (cross-table rule).
-- file_path stores a relative server path; the file itself is kept outside SQLite.

-- 4) One selected timetable per student per semester; unselected alternatives are allowed.
-- TIMETABLE.is_selected should be INTEGER NOT NULL DEFAULT 0 CHECK (is_selected IN (0, 1)).
CREATE UNIQUE INDEX IF NOT EXISTS uq_one_selected_timetable_per_semester
ON TIMETABLE(student_id, semester_id)
WHERE is_selected = 1;

-- 5) Quiz question and answer rules.
-- QUIZ_QUESTION.question_type allowed values:
-- MULTIPLE_CHOICE, TRUE_FALSE, SHORT_ANSWER.
-- MULTIPLE_CHOICE / TRUE_FALSE use QUIZ_OPTION rows.
-- SHORT_ANSWER uses QUIZ_QUESTION.correct_answer as the expected answer.
-- AI_OUTPUT.output_type must be QUIZ for quiz-specific rows (validate in application logic or a trigger).

-- Incorporate the following constraints into QUIZ_ANSWER:
-- UNIQUE (attempt_id, question_id)
-- CHECK (
--   (selected_option_id IS NOT NULL AND written_answer IS NULL)
--   OR
--   (selected_option_id IS NULL AND written_answer IS NOT NULL)
-- )
-- is_correct should be INTEGER with CHECK (is_correct IS NULL OR is_correct IN (0, 1)).
-- Validate that selected_option_id belongs to the same question_id.

-- SQLite storage conventions used in the v2 Data Dictionary:
-- INTEGER: identifiers and integer counters; INTEGER PRIMARY KEY for generated IDs.
-- TEXT: strings, paths, and ISO-8601 DATE/TIME/TIMESTAMP values.
-- REAL: numeric scores, credits, maximum scores, and grade points in this prototype.
-- BOOLEAN: INTEGER 0/1 with explicit CHECK constraints.
-- Use CHECK(length(column) <= N) when a VARCHAR(N)-style maximum length must be enforced.
