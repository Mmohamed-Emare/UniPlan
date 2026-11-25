UniPlan — Phase 3 Consolidated Working Package
Prepared: 20 November 2026

PURPOSE
This package consolidates the latest inspectable Phase 3 design artifacts. It is a working/submission-preparation package, not a claim that every open alignment item has been approved by the TA.

CONTENTS
1. UniPlan_Data_Dictionary_v8_H08_PROPOSED.xlsx
   - Based on v7 H-07 baseline.
   - H-08 proposal appendix adds STUDENT_PREFERENCE, STUDENT_AVAILABILITY, STUDENT_COURSE_PROFILE, and NOTIFICATION.
   - Snapshot counts: 35 entities, 215 documented attributes, 53 relationships (including proposed H-08 additions).
   - H-08 remains PROPOSED ONLY and is not promoted to approved canonical schema.
2. UniPlan_Phase3_SRS_Alignment_Addendum_v1.3.docx
   - Companion clarification to SRS v1.2; does not replace it.
   - Contains requirement wording/mapping updates and open confirmation points.
3. UniPlan_Phase2_SRS_Technology_Aligned_v1.2.docx
   - Existing baseline SRS.
4. UniPlan_Phase3_Sequence_Diagrams_Consolidated_v2.zip
   - Six editable diagrams: SD-02 through SD-07.
   - SD-03 H-06, SD-04 H-07, SD-05 GPA; SD-07 assignment submission.
5. UniPlan_ERD_3_Modules_v4_Submissions.drawio
   - Existing full ERD baseline (v4); not silently modified to include H-08.
6. UniPlan_H08_ERD_Proposal.drawio and UniPlan_H08_Proposed_Schema.sql
   - Separate proposal slice and SQL; keep separate until TA/Class Diagram alignment.
7. UniPlan_Phase3_Consistency_Review_v7_H07.xlsx
   - Prior review snapshot. It predates the addendum and H-08 appendix and should not be read as a completed final approval.

IMPORTANT OPEN ITEMS BEFORE CLAIMING FINAL CONSISTENCY
- Compare the student's actual final Class Diagram against the SRS conceptual model, Data Dictionary v8 and ERD. The standalone final Class Diagram was not available among the inspected artifacts, so this comparison is NOT completed.
- Obtain TA confirmation for H-08 and its four proposed entities, field limits, weekly day numbering, availability overlap/cross-midnight rules, notification scope, and reminder behavior.
- Apply/confirm the SRS addendum changes in the main SRS document if the course expects a single canonical SRS rather than a companion addendum.
- Resolve the remaining cross-document items from review v7 (including AI quiz Short Answer, supported upload formats, GPA traceability, staff/student assignment workspace, Admin scope, optional/later personal-growth features, SQLite concurrency evidence, and shared-login/student-registration UI coverage).
- Validate NFR performance with actual tests before claiming the 20-concurrent-user and response-time targets are met.

TECHNOLOGY / SCOPE BOUNDARY
The project technology baseline remains HTML5, CSS, JavaScript, Jinja, Python/Flask and SQLite, using a modular monolith with MVC. Academic records are simulated. No live university integration, official record modification, assignment grading, or specific AI provider is claimed.

VERSIONING NOTE
Keep the original v7 workbook and existing ERD v4 as historical baselines. The v8 workbook and H-08 files are working artifacts. Do not overwrite source files until TA and Class Diagram alignment is complete.
