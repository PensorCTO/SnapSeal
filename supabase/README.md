# SnapSeal Supabase Pipeline

SnapSeal uses Supabase for OTP authentication, profile-to-wallet mapping, and
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

- `SNAPSEAL_SUPABASE_PROJECT_REF`: project ref from the dashboard URL.
- `SUPABASE_ACCESS_TOKEN`: personal access token for CLI login and CI.
- `SUPABASE_DB_PASSWORD`: remote project database password.
- `SUPABASE_URL`: project API URL for the Flutter app.
- `SUPABASE_ANON_KEY`: rotated public anon key for the Flutter app.

## Local Development

From the repo root:

```bash
scripts/snapseal_supabase_pipeline.sh doctor
scripts/snapseal_supabase_pipeline.sh start
scripts/snapseal_supabase_pipeline.sh reset
scripts/snapseal_supabase_pipeline.sh lint
```

The local project id in `supabase/config.toml` is `snapseal`. Migrations live in
`supabase/migrations/` and should be reviewed before they are pushed remotely.

## Remote Link

The authenticated Supabase MCP account did not list a project named `SnapSeal`
when this pipeline was created, so remote link is driven by environment
variables:

```bash
scripts/snapseal_supabase_pipeline.sh login
scripts/snapseal_supabase_pipeline.sh link
scripts/snapseal_supabase_pipeline.sh push-dry-run
scripts/snapseal_supabase_pipeline.sh push
```

Use `push-dry-run` before `push` so migration history and SQL are visible before
the remote database changes.

## Flutter App

Run the app against the configured SnapSeal project:

```bash
scripts/snapseal_supabase_pipeline.sh app-run
```

The script passes `SUPABASE_URL` and `SUPABASE_ANON_KEY` as Dart defines.

## CI

The GitHub Actions workflow at `.github/workflows/supabase.yml` validates
migrations on pull requests. Manual deployment requires these repository
secrets:

- `SUPABASE_ACCESS_TOKEN`
- `SNAPSEAL_SUPABASE_PROJECT_REF`
- `SNAPSEAL_SUPABASE_DB_PASSWORD`
