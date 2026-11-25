# UniPlan
### Intelligent Academic Planning and Student Productivity Platform

**Course:** CSAI 203 – Software Engineering  
**Institution:** Zewail City of Science and Technology  
**Project Type:** Individual Project  
**Current Deliverable:** Phase 3 – Software Design

---

## 1. Project Overview

UniPlan is an academic planning and student productivity platform designed to help students organize their academic activities, plan course schedules, monitor GPA, and manage their personal study routines.

The project aims to bring essential academic planning and productivity features together in one organized platform.

## 2. Main Modules

- **Identity and Access Management:** User accounts, authentication, and role-based access.
- **Academic Catalogue and GPA:** Academic course information and GPA calculation.
- **Course Planning and Timetable:** Course selection, prerequisite validation, conflict detection, and timetable planning.
- **Study Planning and Productivity:** Personal study planning, goals, routines, and progress tracking.
- **AI Study Lab:** An optional, provider-neutral module for study assistance using user-provided learning materials.

## 3. Technology Stack

| Layer | Technology |
|---|---|
| Frontend | HTML, CSS, JavaScript |
| Backend | Python, Flask, Jinja |
| Database | SQLite |
| Architecture | Modular Monolith, MVC |
| Design Diagrams | diagrams.net (draw.io) |

## 4. Phase 3 Submission Contents

The complete Phase 3 submission package is available in:

`docs/phase-3/submission/UniPlan_Phase3_Submission/`

Main deliverables:

- [Design Document – PDF](docs/phase-3/submission/UniPlan_Phase3_Submission/UniPlan_Phase3_Design_Document.pdf)
- [Design Document – DOCX](docs/phase-3/submission/UniPlan_Phase3_Submission/UniPlan_Phase3_Design_Document.docx)
- [Submission README](docs/phase-3/submission/UniPlan_Phase3_Submission/README_Submission.txt)

The package also includes:

- System architecture diagram.
- Detailed UML class diagram.
- Entity Relationship Diagram (ERD).
- Seven sequence diagrams.
- Database SQL schema and data dictionary.
- UI wireframes and design previews.
- Supporting design notes and reference documents.

Open `.drawio` files using [diagrams.net](https://app.diagrams.net/).

## 5. Architecture and Data Scope

UniPlan is designed as a modular monolithic application following the MVC architectural pattern.

The design uses simulated academic data. It does not claim integration with Zewail City's live systems, modification of official student records, or actual course registration.

The GPA calculator follows a generic 4.0-scale project convention; it should not be interpreted as an official university grading policy.

## 6. Design Status and Limitations

This repository contains the Phase 3 design deliverables. It does **not** represent a completed or deployed application.

Some design items remain subject to confirmation:

- Proposed H-08 entities require TA approval.
- M-16 optional entities depend on confirmation of the approved project scope.
- The AI Study Lab is optional; no live external AI provider integration is claimed.
- The included SQLite validation log records 33 PASS results. The validator script is not included in the submission package.
- No application runtime or performance results are claimed.

The SRS v1.2 and Addendum v1.3 documents are included as reference material for design traceability, not as a resubmission of Phase 2.

## 7. Project Purpose

The purpose of this project is to apply software engineering principles to the analysis and design of a practical academic planning platform, producing structured requirements, architecture, UML models, database design, and interface wireframes.

---

**UniPlan – CSAI 203 Software Engineering Project**
