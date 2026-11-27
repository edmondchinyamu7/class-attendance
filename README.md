# ClassPilot — Malawi Secondary School Management

A Next.js App Router + TypeScript + Tailwind foundation for a multi-role secondary-school management system (Forms 1–4).

## Working branch

`feat/malawi-school-management-nextjs`

## Included in this phase

- Responsive dashboard UI and school configuration preview.
- Twenty generated sample student records.
- Searchable/filterable student directory and registration preview.
- Fees, attendance and subject catalogue preview.
- Supabase SSR client utilities for browser and server.
- Email/password sign-in through Supabase Auth.
- Auth callback route for invitation/confirmation links.
- Session refresh and protected-page redirect using Next.js middleware.
- Sign-out action and Supabase configuration health endpoint.
- Existing Supabase migrations and account-management Edge Function preserved.

**Demo warning:** dashboard totals and student records are sample data stored in the browser session. They are not yet loaded from or saved to Supabase. Do not enter real student data into the preview modules.

## Stack

- Next.js 15, React 19, TypeScript and Tailwind CSS.
- Supabase Auth, PostgreSQL, Row Level Security and Storage.
- Vercel hosting.

Supabase is the single source of truth. Do not configure Neon or run the removed Neon starter schema. The historical migrations under `supabase/migrations/` were applied to the existing Supabase project; do not replay them against that project.

## Environment

Copy `.env.example` to `.env.local` and set:

```bash
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

Use the project's publishable key in the browser. Never expose a Supabase secret/service-role key through a `NEXT_PUBLIC_` variable or browser bundle.

## Supabase Auth configuration

1. In Supabase Dashboard, open **Authentication → URL Configuration**.
2. Set the Site URL to the production web origin (for example, your Vercel domain).
3. Add local and production callback URLs to Redirect URLs, including `http://localhost:3000/auth/callback` and `https://YOUR-VERCEL-DOMAIN/auth/callback`.
4. Ensure invitation/confirmation email templates redirect to `/auth/callback` and use a supported token-hash or PKCE callback flow.
5. Parent invitations currently originate from the existing `classpilot-account-management` Edge Function and use email. Parent phone OTP is not configured by this Next.js phase; it requires an SMS provider and verified phone-auth setup.

## Run locally

```bash
npm install
npm run dev
```

Open http://localhost:3000.

## Existing database and role model

The checked-in Supabase baseline currently supports `school_admin`, `teacher` and `parent` profiles. The requested Bursar role is not in the existing role constraint and must be added through a reviewed forward-only migration with matching RLS policies before any Bursar account is created. Do not simulate role switching in the UI.

The existing database audit is in `docs/CLASS_PILOT_DATABASE_ARCHITECTURE.md`. It records important follow-up work, including school registration email verification, CORS restrictions, abuse controls, missing student fields, fees, term structure, and confidential MSCE access boundaries.

## Not production complete

The following still require implementation and testing:
- Database-backed student, fees, attendance and results modules.
- Bursar role and least-privilege policies.
- Parent phone OTP and verified SMS delivery.
- Student accounts (not in the existing profile role model).
- Server-side provisioning flows, storage upload policies and audit logging.
- Adversarial RLS tests for cross-school and parent-child isolation.
- Full production build and deployment verification.

Do not use the dashboard preview with real personal or school data until these are complete.
