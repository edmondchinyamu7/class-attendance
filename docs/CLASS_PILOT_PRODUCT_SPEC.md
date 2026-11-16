# ClassPilot — Product Requirements & Development Specification

**Repository:** `edmondchinyamu7/class-attendance`  
**Product:** ClassPilot — Multi-school Management System  
**Status:** Requirements baseline; implementation is not yet complete.

This document records the agreed product scope. It is not evidence that every feature is already implemented, secured, or deployed. Implement features in reviewed phases, with database migrations, server-side authorization, tests, and deployment verification.

## 1. Product goal and platforms

ClassPilot is a multi-school platform connecting school administrators, teachers, parents/guardians, and students. It must support:
- Responsive web application.
- Mobile applications for Android and iOS.
- Shared backend and database.
- Multiple independent schools, with strict separation of each school's records.

Proposed architecture discussed: HTML/CSS/JavaScript web frontend, Flutter mobile apps, Supabase backend/database/authentication, and Vercel for web hosting. Confirm the final deployment design before implementation.

## 2. Roles and authority

### School administrator
The school administrator controls the school's setup and records, including enrolment, staff, classes, subjects, timetables, attendance oversight, results, grading, fees, announcements, reports, academic calendar, library, inventory, maintenance, health and discipline records.

### Teacher
Teachers can access only the classes and subjects assigned to them. They can mark attendance for their assigned classes and upload learning materials for their assigned classes/subjects. They can view permitted academic information but cannot create, edit, approve, or publish student results.

### Parent/guardian
Parents can access only children linked to their account. One parent account can be linked to multiple children, with a way to switch between child profiles. Parents can view permitted results, attendance, fees, notices, timetables, learning materials and approved documents.

### Student
Students have their own login and dashboard. Access is governed by the school's type and calendar rules below. Students can view permitted personal information, results, attendance, timetable, announcements and learning materials. Confidential MSCE information is never exposed through the ordinary student dashboard.

Do not add extra staff roles unless separately approved.

## 3. School registration and account lifecycle

- School registration is the first step and creates the school's administrator account/dashboard.
- School setup must identify whether the institution is a government school or another school type.
- School admin creates student accounts and teacher accounts.
- Parent accounts are initiated by the school admin and linked to one or more students.
- Parent invitation should use both SMS and email where configured. Send a secure invitation/password-setup link, never a plaintext password.
- Student credentials are created by the school admin. The student may continue using the initial password and is not forced to change it at first login; the student may change it later.
- Passwords must be managed by the authentication provider and never stored or displayed as plaintext. Admins must not be able to retrieve a user's password.
- Resolve student login identifier (Student ID or email) during authentication design.

## 4. Multi-school data isolation and security

- Every school-owned record must be associated with a school identifier.
- Supabase Row Level Security (RLS) must enforce school isolation and role-based access at the database layer.
- Parent access must be restricted to explicitly linked children.
- Teacher access must be restricted to assigned classes and subjects.
- UI visibility is not a security boundary; all authorization must be enforced server-side/database-side.
- Keep service-role keys and all privileged secrets out of browser and mobile client bundles.
- Sensitive actions, especially results, MSCE access, medical records, discipline records, account provisioning and administrative overrides, must be audited.
- Use least-privilege access, secure invitation flows, input validation, rate limiting where appropriate, and tested authorization policies.

## 5. School structure, students, subjects and teachers

### Student profile
Store the student's full name, Student ID, date of birth, gender, Form/class, enrolled subjects, parent/guardian details, photograph, contact information, attendance history and academic history.

### Classes and streams
Each school configures the Forms it offers (for example Forms 1–4), number of streams, and stream names. Admins can add, rename, edit and deactivate classes. Support school-specific names such as Form 1A/B/C or other locally chosen stream labels.

### Subjects
- Each school maintains its own list of subjects offered.
- During enrolment, the admin selects the student's subjects.
- Forms 1 and 2 use the school's configured curriculum.
- Where subject choice is allowed after Form 2, students may choose from subjects offered by that school, subject to final school-admin approval.
- Students should receive results only for subjects in which they are enrolled.

### Teacher assignments
The admin assigns teachers to specific classes and subjects. A teacher sees only students and records relevant to those assignments.

## 6. Academic calendar and government-school year alignment

- Government schools must follow the official Ministry of Education academic-year plan, including the published school opening and closing dates.
- The system must use the assigned government academic-year date range as the boundary for the relevant school year.
- Other school types must not be assigned dates outside the government academic-year range assigned to them. Their detailed term arrangements may be configured by the school within that range, subject to the product's final calendar rules.
- School admins manage the school's applicable term dates, examination periods, holidays and school events within the permitted range.
- Do not invent or hardcode future Ministry dates. The official calendar must be maintained from an authoritative Ministry source and versioned by academic year.
- Calendar changes must not silently rewrite historical attendance, results or other records.

## 7. Student dashboard availability

- Boarding schools: student dashboard is locked during term time and automatically unlocked during official school holidays/end-of-term breaks; it locks again when the next term begins.
- Day schools: student dashboard remains available throughout the term.
- School admin may temporarily unlock an individual boarding student's dashboard for an approved special circumstance.
- Dashboard locking must not interrupt record storage or admin/parent access.
- MSCE confidentiality rules remain in force regardless of dashboard availability.

## 8. Attendance and student conduct

- Teachers mark students Present, Absent or Late for assigned classes.
- Teachers see attendance for their assigned classes; admins can view and edit school-wide attendance.
- Parents see attendance history and summaries for linked children. Students can see their own attendance when their dashboard is available.
- Notify parents when a child is absent or late, subject to configured notification services.
- Maintain attendance context, including sickness/health-related absence where appropriately recorded and access-controlled.
- Student conduct/behaviour information may be recorded as part of the student's school record. Keep factual, dated entries and restrict access appropriately; avoid subjective public ratings or public-facing labels.

## 9. Academic results, grading and confidential MSCE records

- Only the school administrator can enter, edit, approve and publish results.
- Teachers may view permitted results for assigned students/subjects in read-only mode.
- Parents can view ordinary published results for linked children. Students may view ordinary results when dashboard access is allowed.
- Admin result entry should support a single batch form: choose student, academic year, Form and term; display all enrolled subjects; enter marks; save the batch together.
- Show ordinary results in table and graph formats.
- Each school configures its own grading scale. Calculate grades from that school's scale.
- Retain ordinary academic records from Form 1 Term 1 through Form 4 Term 2, including after a student graduates or leaves.
- Form 4 Term 3 MSCE examination records are confidential and separately restricted. Exclude them from ordinary dashboards, reports and graphs. Only specifically authorised school-admin access may view or manage them; audit all access and changes.
- Teachers, parents and students must not access confidential MSCE records through ordinary dashboards.

## 10. Promotion and student progression

At the end of the academic year, the school admin can mark students as promoted, repeated or transferred. Retain historical class placement and academic records after progression.

Promotion must follow the school's configured passing standards. Do not automatically promote a student solely because the academic year has ended.

## 11. Timetable and examinations

### Timetable
- Admin configures classes, subjects, teachers, days, times, classrooms and breaks.
- Timetable follows a repeating/rotating schedule. Exact rotation cycle (weekly or multi-week) remains to be confirmed before implementation.
- Admin can change a teacher assigned to a lesson. The updated timetable must replace stale assignments and notify affected teachers.
- Teachers see their weekly teaching timetable; parents see their child's class timetable; students see their timetable when their dashboard is available.
- Teacher reminder is intended five minutes before a lesson, showing subject, class, time and classroom. Support mobile push and optional SMS/email where configured.
- Reminder scheduling must be updated/cancelled when a lesson changes so a former teacher does not receive stale reminders.

### Examinations
- Admin creates examination timetables with examination name/type, subjects, dates, start/end times, venues and relevant classes/Forms.
- Relevant teachers, parents and students can view the applicable timetable.
- Provide downloadable PDF timetables.

## 12. Learning Materials Centre

This is a learning-materials feature only, not an assignment or homework submission system.
- Teachers upload notes, study guides, PDFs, presentations and other subject learning resources.
- Organise materials by Form, class and subject.
- Teachers publish directly to their assigned classes/subjects; no pre-publication admin approval is required.
- Admin retains the ability to manage or remove material when necessary.
- Students access materials for enrolled subjects when their dashboards are unlocked. Parents may view materials shared with their children.

## 13. Fees

- Admin configures fees per term and manually records payments.
- Calculate outstanding balances and retain payment history.
- Parents see fees charged, amounts paid, balances, payment history and deadlines for linked children.
- No payment gateway or cash/bank/mobile-money integration is in scope at this stage.
- Notify parents by SMS/email when fees are updated or a new balance is recorded, when those services are configured.

## 14. Announcements and notifications

- Admin creates school announcements, exam timetables, holidays/closures, parent meeting dates and notices.
- Teachers see relevant school announcements; parents see notices relevant to their children; students see announcements when their dashboards are available.
- Important announcements may be sent by SMS and email.
- Parent notification events include newly published results, absence/late status, fee updates/new balances and important notices.
- Do not claim SMS, email, push or scheduled reminders are operational until providers, credentials, templates, queues/schedulers and delivery tests are configured.

## 15. Reports, imports and exports

Admin report centre includes:
- Individual student performance.
- Class performance.
- Attendance.
- Fees.
- Enrolment.

Support PDF and Excel downloads; CSV is also useful for data exchange. Parents can only access reports for linked children.

Support bulk student import/export through CSV/XLSX. Validate required fields, duplicate Student IDs and malformed data before committing records. Support exports for student registers, results, attendance and class lists.

## 16. Digital identity cards

### Student ID
Include photograph, full name, Student ID, date of birth, automatically calculated current age, school name/logo, current Form/class, academic year and QR code.

### Teacher/staff ID
Include photograph, full name, Staff ID, school name/logo, assigned subjects/classes and QR code.

### Parent ID
Include photograph, full name, Parent ID, school name/logo, linked children's names and QR code.

Cards should be viewable in the appropriate dashboard and downloadable as PDF. QR codes must resolve through a secure verification flow and reveal only the minimum permitted identity information. Do not encode sensitive details, passwords, medical data or confidential results directly in the QR code.

## 17. Parent-accessible documents

Parents can download documents explicitly shared with them, such as admission letters, fee statements, report cards, school notices and authorised transfer documents. Only documents approved for parent access should be visible.

## 18. Library management

Include book registration and categorisation, availability, borrowing/return records, expected return dates, overdue tracking, student borrowing history and inventory reports. Access should be granted to authorised school personnel.

## 19. School inventory

Track school property such as computers, desks, chairs, laboratory equipment, sports equipment and other resources. Each item should record name, category, quantity, condition, acquisition date and location. Track damaged, missing, repaired and disposed items.

## 20. Maintenance

Record repair requests with description, location, optional photographs, priority, repair costs, status (pending/ongoing/completed) and maintenance history.

## 21. Student health records

- Maintain restricted student clinic visit, sickness, injury, emergency, allergy, medication (where relevant), visit date, action taken and referral records.
- Parents should be notified when their child visits the clinic, becomes sick, experiences an injury or has a medical emergency, using configured communication channels.
- Parents can submit medical information for school-admin verification before it becomes part of the approved confidential health profile.
- Before approval, the parent submission should collect: student full name and Student ID; known allergies; existing medical conditions; current medication if applicable; relevant previous serious medical conditions; emergency contact name and phone; preferred hospital/health centre; safety-relevant instructions; and supporting documents if available.
- Admin can approve or reject with a reason. Parents may submit updates when details change.
- Health records are confidential. Teachers may see only the minimum information needed to protect student safety; only authorised personnel manage full health records.

## 22. Student discipline records

- Record dated disciplinary incidents, factual descriptions, actions taken, follow-up notes/outcomes and authorised supporting documents.
- Maintain a confidential history with role-restricted access.
- Parents receive only information specifically approved for parent access.
- Do not expose disciplinary records to unrelated students or unauthorised staff.

## 23. Explicitly excluded from current scope

- Visitor management.
- School transport/bus management.
- Homework or assignment submission workflow.
- Online fee payment gateway/integration.
- Additional staff permission tiers beyond the agreed school-admin/teacher/parent/student model, unless later approved.

## 24. Implementation and release safeguards

1. Audit the current repository and database schema before changing existing application code.
2. Produce a phased implementation plan and data model before adding modules.
3. Implement schema changes as version-controlled SQL migrations.
4. Implement and test RLS policies for every school-owned table and every role.
5. Use secure Edge Functions/server-side operations for privileged account provisioning and sensitive actions.
6. Add automated tests for cross-school isolation, parent-child access, teacher assignment boundaries, admin-only results, confidential MSCE, health and discipline privacy, and dashboard lock rules.
7. Test imports/exports, QR verification, PDF generation, and notification delivery.
8. Keep development and production environments separate; never commit secrets.
9. Deploy incrementally and report exactly what is implemented, what is tested, and what remains pending.

## 25. Decisions still requiring confirmation

- Final project name/branding beyond ClassPilot.
- Confirm final web/mobile implementation stack and deployment arrangement.
- Student login identifier (Student ID or email).
- Teacher account invitation and initial-password flow.
- Exact timetable rotation cycle.
- Detailed calendar rules for non-government schools within their assigned government academic-year range.
- The source and maintenance process for official Ministry academic-year dates.
- Which staff are authorised to manage library, inventory, maintenance, health and discipline records within the agreed role model.
- Whether QR verification requires staff sign-in and what minimum fields it may reveal.
