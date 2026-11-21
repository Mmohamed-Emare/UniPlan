UNIPLAN — PHASE 3 DESIGN SUBMISSION PACKAGE
Prepared: 21 November 2026

MAIN SUBMISSION DOCUMENT
- UniPlan_Phase3_Design_Document.pdf
- Editable source: UniPlan_Phase3_Design_Document.docx

EDITABLE DESIGN SOURCES
- diagrams/architecture/: four-page system architecture / MVC model.
- diagrams/class-diagram/: detailed seven-page UML class model.
- diagrams/erd/: four-page reconciled ERD.
- diagrams/sequence/: seven editable sequence diagrams, SD-01 through SD-07.

DATABASE DELIVERABLES
- database/UniPlan_SQLite_Schema_v9_1_Final.sql
- database/UniPlan_Data_Dictionary_v9_Reconciled.xlsx
- database/sqlite_validation_log.txt

UI DELIVERABLES
- ui-wireframes/: eight representative screens.
- previews/UI_Wireframes_Contact_Sheet.png: visual index of the eight screens.

OPENING DRAW.IO FILES
Open https://app.diagrams.net/ and choose File > Open From > Device, then select a .drawio source file. The .drawio files are editable source, not screenshots.

IMPORTANT DESIGN STATUS NOTES
1. The physical SQL baseline contains 26 core SQLite tables. The Data Dictionary also documents five M-16 optional/deferred entities and four H-08 proposed entities. H-08 remains a proposal pending TA approval.
2. The reconciled ERD has 53 relationships: 48 non-H-08 and five proposed H-08. The detailed ERD and seven-page Class Diagram are provided as editable draw.io sources.
3. GPA scale labels, numeric boundaries, grade-point values and rounding policy remain subject to TA confirmation.
4. M-16 optional scope (Course Material, Announcement, Goal, Routine and Journal Entry) requires confirmation against the approved Phase 1 scope.
5. FR-13 task status naming and FR-15 study-session status naming differ between the Addendum and SQL. These discrepancies are documented in the Design Document and should be agreed with the TA before implementation.
6. The supplied SQLite validation log reports 33 PASS results; its validator script was not included in the archive. The log's T05/T10 and T15/T16 limitations are described in Appendix B. No application-level NFR performance, usability or coverage results are claimed.
7. The AI provider has not been selected. Any demo using mock/deterministic output must identify it as mock; no live external integration is claimed.
8. The SRS v1.2 file under references/ is included for traceability only; this package does not constitute a Phase 2 resubmission.

This is a Phase 3 design package. It contains design documents, editable diagrams, database artifacts, and UI mockups; it does not claim that the complete application has been implemented.
