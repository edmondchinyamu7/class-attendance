# Supabase Authentication Integration — ClassPilot

## Scope

This phase adds the Next.js SSR authentication plumbing. It does not modify the live Supabase schema or deploy the existing Edge Function.

## Implemented

- Browser and request-scoped server clients using `@supabase/ssr`.
- Next.js middleware refreshes sessions and validates JWT claims with `auth.getClaims()`.
- Unauthenticated visitors are redirected to `/login`.
- Email/password sign-in verifies the profile row and checks that the trusted `app_metadata` role and school ID match the profile.
- Auth callback supports PKCE code exchange and token-hash invitation/confirmation flows.
- Sign-out clears the Supabase session.

Authorization never trusts editable `user_metadata`. The existing RLS model uses trusted `app_metadata.role` and `app_metadata.school_id`, and the database remains the final authorization boundary.

## Existing role mismatch

The checked-in database migrations constrain profiles to:
- `school_admin`
- `teacher`
- `parent`

The UI requirements also call for a Bursar. That role is not yet supported by the current database constraint or a reviewed set of Bursar-specific RLS policies. Do not add Bursar by changing only the UI or user metadata. Add a forward-only migration and test each table's allowed operations first.

Student login is also not present in the current profile schema.

## Parent sign-in

Existing parent onboarding uses an email invitation after the school verifies parent name, phone, email and student code. This Next.js phase supports the resulting email/password login. Phone OTP is not enabled here because the Supabase Auth phone provider and an SMS delivery provider must first be configured and tested. A phone number stored in `profiles.phone` is not, by itself, an authenticated phone identity.

## Required Supabase Dashboard configuration

- Add local and production callback URLs to Auth URL Configuration.
- Set Site URL to the deployed web origin.
- Ensure invitation/confirmation templates redirect to `/auth/callback` and use the matching PKCE or token-hash flow.
- Enable leaked-password protection.
- Review email confirmation settings and do not auto-confirm unverified public school registrations.
- Restrict the existing account-management Edge Function CORS origins to approved deployment origins.
- Add abuse/rate limiting to public registration before production use.

## Security validation still required

- Test unauthenticated redirect and valid login/logout.
- Test a teacher cannot read unassigned classes or subjects.
- Test a parent cannot read any unlinked student's fees, results, attendance or profile.
- Test one school cannot read or modify another school's records.
- Test school_admin operations and deny privileged operations to teacher and parent.
- Test every RLS policy for SELECT, INSERT, UPDATE (including WITH CHECK) and DELETE as applicable.
- Run Supabase security advisors after reviewed schema changes.

The Supabase project management tools were not able to access the live project during this session, so no database query, migration, Auth setting, or Edge Function was changed or verified.
