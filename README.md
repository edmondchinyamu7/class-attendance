# ClassPilot — School Management System

A separated, maintainable frontend structure for the existing ClassPilot application.

## Project structure

```text
ClassPilot_Professional/
├── index.html
├── assets/
│   ├── css/
│   │   └── styles.css
│   └── js/
│       └── app.js
└── README.md
```

## Documentation and database migrations

- [Product requirements and all previously agreed ClassPilot updates](docs/CLASS_PILOT_PRODUCT_SPEC.md)
- [Database architecture and security audit](docs/CLASS_PILOT_DATABASE_ARCHITECTURE.md)
- Supabase migration history is version-controlled in `supabase/migrations/`.

The six migration files were recovered from the connected Supabase migration ledger and committed in their original timestamp order. They document the database changes already applied to the live project. **Do not replay them against the same live database**; use them as the migration baseline for review, local setup and future forward-only changes.

## Run locally

Open `index.html` in a browser, or serve this folder with a local static web server. The app loads the Supabase JavaScript client from its CDN and uses the existing Supabase project configuration already present in `assets/js/app.js`.

## Deployment

For Vercel or GitHub Pages, deploy the contents of this folder. Keep `index.html` at the deployment root so the relative `assets/` paths resolve.

## Important security notes

- The browser file must contain only the Supabase publishable/anon key. Never put a service-role key or other server secret in `app.js`.
- Enforce school and parent-child data boundaries with Supabase Row Level Security (RLS). Hiding a menu item is not an authorization control.
- Teacher sign-in remains intentionally unavailable until the teacher provisioning flow and teacher-specific RLS policies are implemented and tested.
- Parent invitations depend on the deployed `classpilot-account-management` Edge Function and correctly configured Auth email delivery / redirect settings.

## Current scope

The repository includes the existing frontend, the agreed product requirements, a database/security audit, and the six recorded Supabase migrations. The requirements document includes the previously agreed school registration, student/teacher/parent/student dashboards, subject enrolment, grading and results history, MSCE confidentiality, boarding/day-school calendar access, learning materials, attendance, timetable, fees, announcements, health, discipline, digital IDs, library, inventory, maintenance, reports, exports and parent documents. These are product requirements, not claims that every module is implemented. New database changes must be added as reviewed forward-only migrations and tested against role-specific RLS policies.
