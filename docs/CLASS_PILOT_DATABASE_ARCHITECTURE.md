# ClassPilot — Database Architecture & Security Audit

**Repository:** `edmondchinyamu7/class-attendance`  
**Supabase project:** `ClassPilot` (`vofaqjpndpydhszfntnk`)  
**Audit date:** 16 November 2026  
**Status:** Design and read-only audit only. No database schema, RLS policy, Edge Function, or application code was changed during this audit.

## 1. Current environment

- The frontend is a static HTML/CSS/JavaScript application using Supabase JS v2.
- The frontend uses a Supabase publishable key. A publishable key is intended for client use; service-role/secret keys must remain server-side.
- The live Supabase project is active and uses PostgreSQL 17.
- Six migrations are recorded in the live Supabase project.
- The repository currently has no checked-in `supabase/` migration/configuration directory. The live database therefore cannot yet be reproduced reliably from the repository alone.
- An active `classpilot-account-management` Edge Function exists (version 4). Its deployment has JWT verification disabled at the gateway, while protected parent/teacher actions manually extract and validate the bearer token with Supabase Auth. Public school registration is a separate unauthenticated action.

## 2. Existing database foundation

The live `public` schema currently contains these 11 tables:

| Table | Current purpose |
|---|---|
| `schools` | School identity and administrator link |
| `profiles` | Authenticated staff/parent profile and role |
| `students` | Student enrolment and parent contact fields |
| `parent_student_links` | Parent-to-student relationships |
| `attendance` | Daily attendance |
| `lesson_notes` | Learning materials |
| `academic_results` | Assessment scores |
| `school_subjects` | School-specific subject catalogue |
| `student_subjects` | Student subject enrolment |
| `teacher_assignments` | Teacher/class/subject assignments |
| `school_grading_scales` | School-specific grading bands |

RLS is enabled on all 11 listed tables. The existing policies include school-admin access, parent-child access, teacher-assignment access, and school-specific subject/grading access. The private helper `private.teacher_can_access_student(...)` checks teacher role, school, class and subject assignment before granting teacher access to a student's assigned records.

This is a useful foundation. Preserve it and evolve it through reviewed migrations rather than replacing it wholesale.

## 3. Findings that need attention

### Security and account lifecycle

1. **Leaked-password protection is disabled.** Supabase's security advisor reports this warning. Enable leaked-password protection in Auth settings before production.
2. **Public school registration currently auto-confirms the email.** The Edge Function creates the first admin with `email_confirm: true`. This does not prove that the registrant controls the email address. Change the flow to require verified email ownership before the account is treated as active.
3. **The account-management function allows wildcard CORS.** Restrict allowed origins to the real ClassPilot web origins once the deployment domains are final. Keep explicit OPTIONS handling.
4. **Public school registration needs abuse controls.** Add rate limiting and an appropriate bot/abuse check before making public registration widely available.
5. **Sensitive data is not yet modelled.** Health, discipline, confidential MSCE, and detailed parent/guardian records need separate access boundaries, not broad student-table access.
6. **Student authentication is not represented in the current profile schema.** The profile role constraint currently lists school_admin, teacher and parent only; the students table has no authenticated-user link. Student login therefore needs a deliberate design and migration.

### Data model gaps

- Student records do not yet include the full agreed profile (for example date of birth, gender, photograph, admission status and historical class placements).
- Classes/streams and academic-year/term calendars are stored as free-text concepts in current application fields rather than normalized school-owned entities.
- Results currently lack a structured academic-year/term relationship, publication workflow and separate confidential MSCE storage boundary.
- Timetables, examination schedules, fees/payments, announcements, audit events, digital identity cards, parent documents, library, inventory and maintenance are not present in the current table set.
- Health and discipline records are not present and should not be added as unrestricted columns on `students`.

### Performance advisor results

Supabase's performance advisor reported:
- 22 RLS policy expressions that can be optimized by wrapping stable auth calls as scalar subqueries (for example `(select auth.uid())`).
- 10 foreign-key relationships without covering indexes.
- Multiple permissive policies for the same table/action on several existing tables.
- Several indexes not yet used by the current workload. Do not remove these solely from an early low-volume audit; reassess after realistic usage.

These are optimization findings, not proof that cross-school access is currently possible. RLS policies still require role-by-role adversarial tests.

## 4. Recommended target architecture

### Core identity and tenancy

- `schools`: one row per school; all school-owned records reference `school_id`.
- `profiles`: one authenticated human account, with server-controlled role and school assignment. Do not trust user-editable metadata for authorization.
- `students`: school-owned student record, with a nullable unique `auth_user_id` for student login when enabled.
- `parent_student_links`: many-to-many relationship, allowing one parent to access multiple children.
- Keep school identity in a trusted server-controlled claim or resolve it through a protected profile lookup. Never accept a client-supplied `school_id` as proof of authority.

### School structure and academic history

- `academic_years` and `terms`: versioned school-year boundaries and term dates, with source and approval metadata for official Ministry calendars.
- `classes`: school, academic year, Form, stream and display name.
- `school_subjects`: school-specific catalogue.
- `student_enrolments` and `student_subjects`: dated class placement and subject enrolment, retaining historical records.
- `teacher_assignments`: teacher, class, subject and effective date range.

### Academic records

- `academic_results`: ordinary results linked to student, academic year, term and subject; include score/max score, entered-by, approval/publication state and timestamps.
- Teachers: read-only access to permitted assigned results.
- Parents: read-only access to published results for linked children.
- Students: read-only access to their own published ordinary results when dashboard rules permit.
- MSCE: place Form 4 Term 3 confidential results in a separate restricted table/schema or a tightly controlled privileged interface. Never expose them through ordinary result queries, views, reports or dashboards. Audit every read and write.

### Sensitive and operational modules

Create dedicated tables and policies for:
- Fees, fee items, payments and balances.
- Timetable cycles, lessons and examination schedules.
- Announcements and notification delivery records.
- Health submissions, verified health profiles and clinic visits.
- Discipline incidents and parent-visible approvals.
- Parent-shared documents and secure file metadata.
- Digital ID records and QR verification tokens.
- Library books, loans and returns.
- Inventory assets and maintenance requests.
- Audit events for sensitive reads, writes, approvals, exports and administrative overrides.

Health, MSCE and discipline records should use stricter access paths than general student records. Use private storage buckets for sensitive documents, short-lived signed URLs, and explicit authorization checks.

## 5. RLS authorization matrix

| Resource | School admin | Teacher | Parent | Student |
|---|---|---|---|---|
| School setup | Own school manage | No | No | No |
| Student profile | Own school manage | Assigned students, minimum required fields | Linked children only | Own record only |
| Attendance | Own school manage | Assigned classes | Linked children read | Own read |
| Learning materials | Own school manage | Publish for assigned class/subject | Child-shared read | Enrolled subject read |
| Ordinary results | Own school manage/publish | Assigned read-only | Linked child, published only | Own, published only |
| MSCE | Explicitly authorised admin only | No | No | No |
| Fees | Own school manage | No | Linked child read | No by default |
| Health | Specifically authorised school admin workflow | Minimum safety-only view if approved | Own child submission/status and permitted updates | No |
| Discipline | Own school, restricted | Only if specifically required for assigned duties | Only parent-approved items | No |
| Library/inventory/maintenance | School management | No by default | No | No |

The matrix is the target policy baseline. It does not imply that every module or permission is implemented today.

## 6. Migration and implementation sequence

1. **Reproducibility:** retrieve the live migration history and schema into version-controlled `supabase/migrations/`; confirm the checked-in baseline matches the live project before changing it.
2. **Security hardening:** leaked-password protection, verified school-admin email, CORS allowlist, registration abuse controls, and tests for current RLS boundaries.
3. **Identity and school structure:** add student auth linkage, student profile fields, normalized classes, academic years, terms and historical enrolments.
4. **Results redesign:** add term/year references and publication controls; create and test the separate MSCE boundary.
5. **Core school operations:** timetable, examinations, fees, announcements and audit logging.
6. **Restricted modules:** health, discipline, parent documents and private file storage.
7. **School resources:** library, inventory, maintenance and digital ID verification.
8. **Release verification:** test cross-school isolation, parent-child isolation, teacher assignment boundaries, admin-only writes, student self-access, confidential MSCE denial, and dashboard calendar rules using separate test accounts for each role.

## 7. Mandatory tests before release

- A user from School A cannot read, insert, update or delete School B records, even by changing IDs in a request.
- A parent cannot read a child who is not linked to that parent, including through nested relations, reports, storage paths or exports.
- A teacher cannot access students outside their assigned class/subject or write academic results.
- A school admin cannot manage another school's records.
- Students can access only their own allowed records.
- MSCE data is absent from all ordinary result APIs and is denied to teachers, parents and students.
- Health and discipline records are denied by default and exposed only through explicitly approved minimum-access policies.
- UPDATE policies enforce both row visibility and valid new values/ownership using `USING` and `WITH CHECK`.
- Privileged Edge Functions verify the caller and role on the server; no service-role key is shipped to the browser.
- Notifications, storage, exports and scheduled tasks are tested independently before being described as operational.

## 8. Immediate next implementation task

First make the current Supabase database reproducible in GitHub by bringing the six existing migrations into the repository and reconciling them with the live schema. Then harden school registration and Auth settings. Do not add the full module schema in one large migration.
