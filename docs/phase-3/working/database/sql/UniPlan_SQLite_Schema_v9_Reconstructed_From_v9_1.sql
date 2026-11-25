

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA busy_timeout = 5000;

-- ----------------------------------------------------------------------------
-- 1. CORE BASELINE TABLES (26 Entities)
-- ----------------------------------------------------------------------------

CREATE TABLE USER (
    user_id INTEGER PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('STUDENT', 'TA', 'INSTRUCTOR', 'ADMIN')),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL
);

CREATE TABLE STUDENT_PROFILE (
    user_id INTEGER PRIMARY KEY,
    student_number TEXT NOT NULL UNIQUE,
    program TEXT NOT NULL,
    academic_level INTEGER NOT NULL CHECK (academic_level >= 1),
    FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE
);

CREATE TABLE COURSE (
    course_id INTEGER PRIMARY KEY,
    course_code TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    credits INTEGER NOT NULL CHECK (credits > 0),
    department TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
);

CREATE TABLE SEMESTER (
    semester_id INTEGER PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL CHECK (end_date > start_date),
    is_current INTEGER NOT NULL DEFAULT 0 CHECK (is_current IN (0, 1))
);

CREATE TABLE SECTION (
    section_id INTEGER PRIMARY KEY,
    course_id INTEGER NOT NULL,
    semester_id INTEGER NOT NULL,
    section_code TEXT NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    enrolled_count INTEGER NOT NULL DEFAULT 0 CHECK (enrolled_count >= 0 AND enrolled_count <= capacity),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    UNIQUE (course_id, semester_id, section_code),
    FOREIGN KEY (course_id) REFERENCES COURSE(course_id),
    FOREIGN KEY (semester_id) REFERENCES SEMESTER(semester_id)
);

CREATE TABLE SECTION_MEETING (
    meeting_id INTEGER PRIMARY KEY,
    section_id INTEGER NOT NULL,
    day_of_week TEXT NOT NULL CHECK (day_of_week IN ('SATURDAY','SUNDAY','MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY')),
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL CHECK (end_time > start_time),
    location TEXT,
    FOREIGN KEY (section_id) REFERENCES SECTION(section_id) ON DELETE CASCADE
);

-- H-06: All listed prerequisites are required; cycles prevented in service layer
CREATE TABLE COURSE_PREREQUISITE (
    course_id INTEGER NOT NULL,
    prerequisite_course_id INTEGER NOT NULL,
    PRIMARY KEY (course_id, prerequisite_course_id),
    CHECK (course_id <> prerequisite_course_id),
    FOREIGN KEY (course_id) REFERENCES COURSE(course_id) ON DELETE CASCADE,
    FOREIGN KEY (prerequisite_course_id) REFERENCES COURSE(course_id) ON DELETE CASCADE
);

-- H-06: Retains both PASSED and FAILED attempts; any PASSED attempt satisfies prerequisite
CREATE TABLE STUDENT_COMPLETED_COURSE (
    completion_id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    semester_id INTEGER NOT NULL,
    completion_status TEXT NOT NULL CHECK (completion_status IN ('PASSED', 'FAILED')),
    completed_at TEXT NOT NULL,
    FOREIGN KEY (student_id) REFERENCES STUDENT_PROFILE(user_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES COURSE(course_id),
    FOREIGN KEY (semester_id) REFERENCES SEMESTER(semester_id)
);

CREATE TABLE COURSE_STAFF_ASSIGNMENT (
    staff_assignment_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    semester_id INTEGER NOT NULL,
    staff_role TEXT NOT NULL CHECK (staff_role IN ('TA', 'INSTRUCTOR')),
    assigned_at TEXT NOT NULL,
    UNIQUE (user_id, course_id, semester_id),
    FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES COURSE(course_id),
    FOREIGN KEY (semester_id) REFERENCES SEMESTER(semester_id)
);

-- C-03 / C-04: Assignment briefs & immutable versioned final submissions (no grading)
CREATE TABLE ASSIGNMENT (
    assignment_id INTEGER PRIMARY KEY,
    course_id INTEGER NOT NULL,
    semester_id INTEGER NOT NULL,
    created_by_user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    due_at TEXT NOT NULL,
    allowed_extensions TEXT NOT NULL,
    max_file_size_mb INTEGER NOT NULL CHECK (max_file_size_mb > 0),
    created_at TEXT NOT NULL,
    FOREIGN KEY (course_id) REFERENCES COURSE(course_id),
    FOREIGN KEY (semester_id) REFERENCES SEMESTER(semester_id),
    FOREIGN KEY (created_by_user_id) REFERENCES USER(user_id)
);

CREATE TABLE ASSIGNMENT_SUBMISSION (
    submission_id INTEGER PRIMARY KEY,
    assignment_id INTEGER NOT NULL,
    student_id INTEGER NOT NULL,
    version_number INTEGER NOT NULL CHECK (version_number >= 1),
    original_file_name TEXT NOT NULL,
    stored_file_path TEXT NOT NULL,
    file_extension TEXT NOT NULL,
    file_size_bytes INTEGER NOT NULL CHECK (file_size_bytes > 0),
    receipt_code TEXT NOT NULL UNIQUE,
    submitted_at TEXT NOT NULL,
    UNIQUE (assignment_id, student_id, version_number),
    FOREIGN KEY (assignment_id) REFERENCES ASSIGNMENT(assignment_id),
    FOREIGN KEY (student_id) REFERENCES STUDENT_PROFILE(user_id)
);

-- C-05: Separated Course Planning & Timetable Generation
CREATE TABLE STUDENT_COURSE_PLAN (
    plan_id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL,
    semester_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (student_id) REFERENCES STUDENT_PROFILE(user_id) ON DELETE CASCADE,
    FOREIGN KEY (semester_id) REFERENCES SEMESTER(semester_id)
);

CREATE TABLE STUDENT_PLAN_SECTION (
    plan_id INTEGER NOT NULL,
    section_id INTEGER NOT NULL,
    PRIMARY KEY (plan_id, section_id),
    FOREIGN KEY (plan_id) REFERENCES STUDENT_COURSE_PLAN(plan_id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES SECTION(section_id)
);

CREATE TABLE TIMETABLE (
    timetable_id INTEGER PRIMARY KEY,
    plan_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    is_selected INTEGER NOT NULL DEFAULT 0 CHECK (is_selected IN (0, 1)),
    generation_mode TEXT NOT NULL CHECK (generation_mode IN ('MANUAL', 'AUTO')),
    generated_at TEXT NOT NULL,
    FOREIGN KEY (plan_id) REFERENCES STUDENT_COURSE_PLAN(plan_id) ON DELETE CASCADE
);

-- Critical Fix (AUD-01): Enforces at most one selected timetable per course plan
CREATE UNIQUE INDEX ux_one_selected_timetable_per_plan
    ON TIMETABLE(plan_id) WHERE is_selected = 1;

CREATE TABLE TIMETABLE_SECTION (
    timetable_id INTEGER NOT NULL,
    section_id INTEGER NOT NULL,
    PRIMARY KEY (timetable_id, section_id),
    FOREIGN KEY (timetable_id) REFERENCES TIMETABLE(timetable_id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES SECTION(section_id)
);

-- C-05: GPA Calculator (isolated from course planning and completion records)
CREATE TABLE GPA_SCALE (
    grade_scale_id INTEGER PRIMARY KEY,
    letter_grade TEXT NOT NULL UNIQUE,
    min_score REAL NOT NULL,
    max_score REAL NOT NULL CHECK (max_score >= min_score),
    grade_points REAL NOT NULL CHECK (grade_points >= 0.0)
);

CREATE TABLE GPA_ENTRY (
    gpa_entry_id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    semester_id INTEGER NOT NULL,
    input_type TEXT NOT NULL CHECK (input_type IN ('NUMERIC', 'LETTER')),
    numeric_score REAL,
    grade_scale_id INTEGER NOT NULL,
    created_at TEXT NOT NULL,
    CHECK (
        (input_type = 'NUMERIC' AND numeric_score IS NOT NULL) OR
        (input_type = 'LETTER' AND numeric_score IS NULL)
    ),
    FOREIGN KEY (student_id) REFERENCES STUDENT_PROFILE(user_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES COURSE(course_id),
    FOREIGN KEY (semester_id) REFERENCES SEMESTER(semester_id),
    FOREIGN KEY (grade_scale_id) REFERENCES GPA_SCALE(grade_scale_id)
);

-- H-07: Independent Personal Tasks & Plan-Bound Study Sessions
CREATE TABLE STUDY_PLAN (
    plan_id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL,
    semester_id INTEGER,
    title TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL CHECK (end_date >= start_date),
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'ARCHIVED')),
    created_at TEXT NOT NULL,
    FOREIGN KEY (student_id) REFERENCES STUDENT_PROFILE(user_id) ON DELETE CASCADE,
    FOREIGN KEY (semester_id) REFERENCES SEMESTER(semester_id)
);

CREATE TABLE PERSONAL_TASK (
    task_id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL,
    course_id INTEGER,
    title TEXT NOT NULL,
    description TEXT,
    due_at TEXT,
    priority TEXT NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH')),
    status TEXT NOT NULL DEFAULT 'TODO' CHECK (status IN ('TODO', 'IN_PROGRESS', 'COMPLETED')),
    estimated_minutes INTEGER CHECK (estimated_minutes IS NULL OR estimated_minutes > 0),
    created_at TEXT NOT NULL,
    completed_at TEXT,
    FOREIGN KEY (student_id) REFERENCES STUDENT_PROFILE(user_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES COURSE(course_id)
);

CREATE TABLE STUDY_SESSION (
    session_id INTEGER PRIMARY KEY,
    plan_id INTEGER NOT NULL,
    course_id INTEGER,
    task_id INTEGER,
    title TEXT NOT NULL,
    scheduled_start TEXT NOT NULL,
    scheduled_end TEXT NOT NULL CHECK (scheduled_end > scheduled_start),
    actual_start TEXT,
    actual_end TEXT CHECK (actual_end IS NULL OR actual_start IS NULL OR actual_end >= actual_start),
    status TEXT NOT NULL DEFAULT 'PLANNED' CHECK (status IN ('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'MISSED', 'SKIPPED')),
    notes TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (plan_id) REFERENCES STUDY_PLAN(plan_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES COURSE(course_id),
    FOREIGN KEY (task_id) REFERENCES PERSONAL_TASK(task_id) ON DELETE SET NULL
);

-- AI Study Lab (6 Core Baseline Entities)
CREATE TABLE STUDY_UPLOAD (
    upload_id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL,
    course_id INTEGER,
    title TEXT NOT NULL,
    original_file_name TEXT NOT NULL,
    stored_file_path TEXT NOT NULL,
    file_type TEXT NOT NULL CHECK (file_type IN ('PDF', 'TXT')),
    extracted_text TEXT,
    extraction_status TEXT NOT NULL CHECK (extraction_status IN ('PENDING', 'READY', 'FAILED')),
    uploaded_at TEXT NOT NULL,
    FOREIGN KEY (student_id) REFERENCES STUDENT_PROFILE(user_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES COURSE(course_id)
);

CREATE TABLE AI_OUTPUT (
    ai_output_id INTEGER PRIMARY KEY,
    upload_id INTEGER NOT NULL,
    output_type TEXT NOT NULL CHECK (output_type IN ('SUMMARY', 'QUIZ')),
    content_text TEXT,
    provider_tag TEXT NOT NULL,
    disclaimer_shown INTEGER NOT NULL DEFAULT 1 CHECK (disclaimer_shown IN (0, 1)),
    created_at TEXT NOT NULL,
    FOREIGN KEY (upload_id) REFERENCES STUDY_UPLOAD(upload_id) ON DELETE CASCADE
);

CREATE TABLE QUIZ_QUESTION (
    question_id INTEGER PRIMARY KEY,
    ai_output_id INTEGER NOT NULL,
    question_type TEXT NOT NULL CHECK (question_type IN ('MCQ', 'TRUE_FALSE', 'SHORT_ANSWER')),
    question_text TEXT NOT NULL,
    reference_answer TEXT,
    explanation TEXT,
    display_order INTEGER NOT NULL CHECK (display_order >= 1),
    FOREIGN KEY (ai_output_id) REFERENCES AI_OUTPUT(ai_output_id) ON DELETE CASCADE
);

CREATE TABLE QUIZ_OPTION (
    option_id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    option_label TEXT NOT NULL,
    option_text TEXT NOT NULL,
    is_correct INTEGER NOT NULL DEFAULT 0 CHECK (is_correct IN (0, 1)),
    FOREIGN KEY (question_id) REFERENCES QUIZ_QUESTION(question_id) ON DELETE CASCADE
);

CREATE TABLE QUIZ_ATTEMPT (
    attempt_id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL,
    ai_output_id INTEGER NOT NULL,
    started_at TEXT NOT NULL,
    submitted_at TEXT,
    score_percent REAL,
    FOREIGN KEY (student_id) REFERENCES STUDENT_PROFILE(user_id) ON DELETE CASCADE,
    FOREIGN KEY (ai_output_id) REFERENCES AI_OUTPUT(ai_output_id) ON DELETE CASCADE
);

CREATE TABLE QUIZ_ANSWER (
    answer_id INTEGER PRIMARY KEY,
    attempt_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    selected_option_id INTEGER,
    short_answer_text TEXT,
    is_correct INTEGER CHECK (is_correct IS NULL OR is_correct IN (0, 1)),
    CHECK (
        (selected_option_id IS NOT NULL AND short_answer_text IS NULL) OR
        (selected_option_id IS NULL AND short_answer_text IS NOT NULL)
    ),
    FOREIGN KEY (attempt_id) REFERENCES QUIZ_ATTEMPT(attempt_id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES QUIZ_QUESTION(question_id) ON DELETE CASCADE,
    FOREIGN KEY (selected_option_id) REFERENCES QUIZ_OPTION(option_id)
);

