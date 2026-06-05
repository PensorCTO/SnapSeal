# FactLockCam Supabase Pipeline

FactLockCam uses Supabase for OTP authentication, profile-to-wallet mapping, and
the active-wallet replica of Polygon proof rows. Polygon remains the durable
proof layer.

## Secret Handling

Do not commit Supabase secret keys, database passwords, or personal access
tokens. The key pasted into chat should be rotated in Supabase before it is used
for production or CI.

Use local-only `.env.local` files for developer machines:

```bash
cp .env.example .env.local
```

Required values:

- `FACTLOCKCAM_SUPABASE_PROJECT_REF`: project ref from the dashboard URL.
- `SUPABASE_ACCESS_TOKEN`: personal access token for CLI login and CI.
- `SUPABASE_DB_PASSWORD`: remote project database password.
- `SUPABASE_URL`: project API URL for the Flutter app.
- `SUPABASE_ANON_KEY`: rotated public anon key for the Flutter app.

## Local Development

From the repo root:

```bash
scripts/factlockcam_supabase_pipeline.sh doctor
scripts/factlockcam_supabase_pipeline.sh start
scripts/factlockcam_supabase_pipeline.sh reset
scripts/factlockcam_supabase_pipeline.sh lint
```

The local project id in `supabase/config.toml` is `factlockcam`. Migrations live in
`supabase/migrations/` and should be reviewed before they are pushed remotely.

## Remote Link

The authenticated Supabase MCP account did not list a project named `FactLockCam`
when this pipeline was created, so remote link is driven by environment
variables:

```bash
scripts/factlockcam_supabase_pipeline.sh login
scripts/factlockcam_supabase_pipeline.sh link
scripts/factlockcam_supabase_pipeline.sh migration-list
scripts/factlockcam_supabase_pipeline.sh push-dry-run
scripts/factlockcam_supabase_pipeline.sh push
scripts/factlockcam_supabase_pipeline.sh config-push
```

Prefer these script commands over typing raw `supabase ...` in the shell: the
script loads repo-root `.env.local` first, so remote Postgres commands receive
`SUPABASE_DB_PASSWORD` (the bare CLI does not load `.env.local` by default).

Use `push-dry-run` before `push` so migration history and SQL are visible before
the remote database changes.

**Cursor agents:** execute `push` / `functions deploy` directly when a task requires
hosted schema changes — do not hand off migration steps to the user (see
`.cursor/rules/supabase-agent-ops.mdc`).

Auth settings such as the 6-digit email OTP length live in
`supabase/config.toml`, not database migrations. Run `config-push` after linking
the remote project so the hosted Supabase project uses `auth.email.otp_length =
6`. The Magic Link email template in the hosted dashboard must include
`{{ .Token }}` for typed-number OTP login.

## Flutter App

Run the app against the configured FactLockCam project:

```bash
scripts/factlockcam_supabase_pipeline.sh app-run
```

The script passes `SUPABASE_URL` and `SUPABASE_ANON_KEY` as Dart defines.

## CI

The GitHub Actions workflow at `.github/workflows/supabase.yml` validates
migrations on pull requests. Manual deployment requires these repository
secrets:

- `SUPABASE_ACCESS_TOKEN`
- `FACTLOCKCAM_SUPABASE_PROJECT_REF`
- `FACTLOCKCAM_SUPABASE_DB_PASSWORD`
