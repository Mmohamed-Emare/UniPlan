-- UniPlan C-05 target schema slice (SQLite)
-- Design correction only: personal planning is NOT official enrollment.
-- Review/migrate existing data before applying to a populated database.
PRAGMA foreign_keys = ON;

-- One personal course plan per student and semester (proposed uniqueness rule).
CREATE TABLE STUDENT_COURSE_PLAN (
    plan_id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL,
    semester_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (student_id, semester_id),
    FOREIGN KEY (student_id) REFERENCES STUDENT_PROFILE(user_id),
    FOREIGN KEY (semester_id) REFERENCES SEMESTER(semester_id)
);

-- Student-selected sections are planning choices, not institutional registration.
CREATE TABLE STUDENT_PLAN_SECTION (
    plan_id INTEGER NOT NULL,
    section_id INTEGER NOT NULL,
    PRIMARY KEY (plan_id, section_id),
    FOREIGN KEY (plan_id) REFERENCES STUDENT_COURSE_PLAN(plan_id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES SECTION(section_id)
);

-- TIMETABLE now represents a candidate schedule option belonging to a plan.
-- For a clean target schema, use plan_id instead of old student_id + semester_id.
CREATE TABLE TIMETABLE (
    timetable_id INTEGER PRIMARY KEY,
    plan_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    is_selected INTEGER NOT NULL DEFAULT 0 CHECK (is_selected IN (0,1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES STUDENT_COURSE_PLAN(plan_id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX ux_one_selected_timetable_per_plan
ON TIMETABLE(plan_id) WHERE is_selected = 1;

CREATE TABLE TIMETABLE_SECTION (
    timetable_id INTEGER NOT NULL,
    section_id INTEGER NOT NULL,
    PRIMARY KEY (timetable_id, section_id),
    FOREIGN KEY (timetable_id) REFERENCES TIMETABLE(timetable_id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES SECTION(section_id)
);

-- GPA entries only reference catalog courses. Credits are read from COURSE.credits.
-- A single GPA scale row resolves both numeric and letter input.
CREATE TABLE GPA_ENTRY (
    gpa_entry_id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    semester_id INTEGER NOT NULL,
    input_type TEXT NOT NULL CHECK (input_type IN ('NUMERIC','LETTER')),
    numeric_score REAL,
    grade_scale_id INTEGER NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (
        (input_type = 'NUMERIC' AND numeric_score IS NOT NULL AND numeric_score >= 0)
        OR
        (input_type = 'LETTER' AND numeric_score IS NULL)
    ),
    UNIQUE (student_id, course_id, semester_id),
    FOREIGN KEY (student_id) REFERENCES STUDENT_PROFILE(user_id),
    FOREIGN KEY (course_id) REFERENCES COURSE(course_id),
    FOREIGN KEY (semester_id) REFERENCES SEMESTER(semester_id),
    FOREIGN KEY (grade_scale_id) REFERENCES GPA_SCALE(grade_scale_id)
);

-- Application/service validation still required:
-- 1) Numeric score must fall within exactly one GPA_SCALE interval.
-- 2) Letter input must select an existing GPA_SCALE row.
-- 3) GPA weighted average = SUM(COURSE.credits * GPA_SCALE.grade_points)
--    / SUM(COURSE.credits) for the selected student/term scope.
-- 4) No grade conversion values are supplied here; obtain them from the TA.
-- 5) Do not interpret STUDENT_PLAN_SECTION or TIMETABLE_SECTION as enrollment.
-- 6) Do not run this as-is over an existing database: migrate/archive legacy
--    ENROLLMENT records only after deciding how to preserve any existing data.
