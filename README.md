# ClassPilot — Malawi Secondary School Management

A Next.js App Router + TypeScript + Tailwind starter for a multi-role secondary-school management system (Forms 1–4).

## Current branch

`feat/malawi-school-management-nextjs`

## What is included in this first UI phase

- Responsive school dashboard with dark-blue, white and green styling.
- Demo dashboard metrics: student count, term fees, attendance and top-performing students.
- Twenty generated sample student records.
- Searchable and filterable student directory.
- Student registration modal with Form 1–4, streams A–C, guardian contact, district and day/boarding category.
- Fee balance overview and MWK formatting.
- Subject catalogue for English, Chichewa, Mathematics, Biology, Physics, Chemistry, Agriculture, Geography, History and Life Skills.
- Attendance overview and school configuration for Government/Private plus independent Boarding/Day settings.
- Role selector and English/Chichewa language toggle are UI previews, not authentication or translated content yet.
- Health endpoint at `/api/health`.

**Important:** this is a UI/demo foundation, not a production-ready school system. Demo changes are held in browser memory only. Authentication, role permissions, parent-child account linking, payment recording, real marks entry, report-card generation, image uploads, notifications, audit logs and production-grade database authorization are not yet implemented. Do not enter real student or parent information into the demo.

## Stack

- Next.js 15, React 19, TypeScript
- Tailwind CSS
- Neon Postgres using `@neondatabase/serverless`
- Vercel Blob package included for a future server-side student-photo upload flow

Vercel Postgres is no longer offered as a standalone database product. For a new Vercel deployment, provision Neon through the Vercel Marketplace and configure `DATABASE_URL`. The existing Supabase migrations and audit remain in `supabase/` and `docs/` as the historical database baseline; they are not automatically applied to Neon.

## Run locally

1. Install Node.js 20 or later.
2. Copy `.env.example` to `.env.local`.
3. Set `DATABASE_URL` to a Neon connection string (optional for the UI; required for the health check).
4. Run:

```bash
npm install
npm run dev
```

Open http://localhost:3000.

## Database setup

Review `db/schema.sql` and apply it only to a **new, empty Neon database**. It is a starter schema, not a migration to run against the existing Supabase project. Before production use, add verified authentication and enforce school/role/parent-child authorization on every server action and query. Do not expose database credentials to the browser.

## Vercel deployment

Import this repository/branch into Vercel, configure `DATABASE_URL` and deploy. Student photographs should be uploaded through a server-side route using a private Blob store or controlled access strategy; never put privileged tokens in client code.

## Existing Supabase work

The `supabase/migrations/` directory records migrations already applied to the existing Supabase project. The audit in `docs/CLASS_PILOT_DATABASE_ARCHITECTURE.md` identifies security and data-model gaps. Do not replay those historical migrations against that same live database.
