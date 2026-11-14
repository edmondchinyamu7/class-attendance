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

This is a code-organization pass. It separates HTML, CSS, and JavaScript while preserving the existing application behavior and configuration. It does not create new database tables, change Supabase policies, or claim live end-to-end verification.
