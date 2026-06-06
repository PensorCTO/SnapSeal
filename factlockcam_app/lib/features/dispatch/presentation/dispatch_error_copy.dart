/// User-facing Send Proof / courier origination errors (shared by archive actions
/// and the Dispatch Console).
String friendlyCourierDispatchError(Object error) {
  final message = error.toString();
  if (message.contains('ENABLE_PROOF_LINKS') ||
      message.contains('Send Proof is not available')) {
    return 'Send Proof is disabled in this build. For device QA, add '
        'ENABLE_PROOF_LINKS=true to repo-root .env.local, run '
        './scripts/sync_flutter_dart_defines.sh, then cold-restart with '
        './factlockcam_app/run_device.sh (not hot reload).';
  }
  if (message.contains('Supabase is not configured')) {
    return 'Supabase is not configured for this build.';
  }
  if (message.contains('No authenticated user')) {
    return 'Sign in before generating a courier link.';
  }
  if (message.contains('WEB_ARCHIVE_BASE_URL is unset')) {
    return 'Courier links require WEB_ARCHIVE_BASE_URL at compile time. '
        'Release builds should use '
        '`--dart-define=WEB_ARCHIVE_BASE_URL=https://archive.factlockcam.com`.';
  }
  if (message.contains('ERR_CONNECTION_REFUSED') ||
      message.contains('Connection refused')) {
    return 'The link used an unreachable host (often localhost, which '
        'only works on your dev machine). Production builds should bind '
        'WEB_ARCHIVE_BASE_URL to https://archive.factlockcam.com, then '
        'regenerate the link.';
  }
  if (message.contains('Bucket not found')) {
    return 'Storage bucket "courier-blobs" is missing on this Supabase project. '
        'Deploy migrations (ensure '
        '`20260514220000_web_courier_schema` or '
        '`20260516000000_ensure_courier_blobs_storage_bucket`) '
        'or create the bucket in Storage settings, then retry.';
  }
  if (message.contains('row-level security') ||
      message.contains('row level security')) {
    return 'Upload was blocked by Supabase Storage security rules. Push migrations '
        'to this project — especially '
        '`20260517000000_repair_courier_storage_object_rls` (and '
        '`20260514220000_web_courier_schema`) '
        'so authenticated users may write objects under courier-blobs/{user-id}/, then retry.';
  }
  return message;
}
