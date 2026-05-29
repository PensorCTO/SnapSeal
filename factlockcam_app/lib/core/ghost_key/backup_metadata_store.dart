import 'package:shared_preferences/shared_preferences.dart';

/// Records that the user completed at least one `.factlock` export (brick pre-flight).
class BackupMetadataStore {
  static const _completedAtKey = 'key_backup_completed_at';

  Future<void> markBackupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _completedAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<bool> hasCompletedBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_completedAtKey);
  }
}
