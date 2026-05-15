import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/config/app_config.dart';
import '../../core/crypto/courier_crypto.dart';
import '../../core/crypto/vault_encryption_handler.dart';

class CourierUnlockView extends StatefulWidget {
  const CourierUnlockView({super.key, required this.packageId});

  static const routePath = '/courier';

  final String? packageId;

  @override
  State<CourierUnlockView> createState() => _CourierUnlockViewState();
}

class _CourierUnlockViewState extends State<CourierUnlockView> {
  final _emailController = TextEditingController();
  final _challengeController = TextEditingController();
  final _vault = DefaultVaultEncryptionHandler();

  Map<String, dynamic>? _attemptStatus;
  Uint8List? _verifiedBytes;
  String? _fileExtension;
  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAttemptStatus();
  }

  @override
  void didUpdateWidget(covariant CourierUnlockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageId != widget.packageId) {
      _verifiedBytes = null;
      _fileExtension = null;
      _loadAttemptStatus();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _challengeController.dispose();
    super.dispose();
  }

  Future<void> _loadAttemptStatus() async {
    if (!_canUseBackend) {
      setState(() {
        _attemptStatus = null;
        _message = 'Supabase is not configured for this build.';
      });
      return;
    }

    final packageId = widget.packageId;
    if (packageId == null || packageId.isEmpty) {
      setState(() {
        _attemptStatus = null;
        _message = 'Missing courier package id.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await Supabase.instance.client.rpc(
        'check_courier_attempts',
        params: {'p_package_id': packageId},
      );
      if (!mounted) return;
      setState(() {
        _attemptStatus = Map<String, dynamic>.from(response as Map);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _unlock() async {
    final packageId = widget.packageId;
    if (!_canUseBackend || packageId == null || packageId.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _verifiedBytes = null;
      _fileExtension = null;
    });

    try {
      final response = await Supabase.instance.client.rpc(
        'attempt_courier_unlock',
        params: {
          'p_package_id': packageId,
          'p_verifier_guess': _challengeController.text,
          'p_requestor_email': _emailController.text.trim(),
        },
      );
      final row = _firstRpcRow(response);
      final bucket = row['storage_bucket'] as String;
      final path = row['storage_path'] as String;
      final encryptedBytes = await Supabase.instance.client.storage
          .from(bucket)
          .download(path);
      final verifiedBytes = await CourierCrypto.decryptAndVerifyFingerprint(
        vault: _vault,
        encryptedPayload: encryptedBytes,
        keyBytes: _vault.decodeKey(row['key'] as String),
        expectedFingerprint: row['asset_hash'] as String,
      );

      if (!mounted) return;
      setState(() {
        _verifiedBytes = verifiedBytes;
        _fileExtension = (row['file_extension'] as String).toLowerCase();
        _message = 'Verified SHA-256 fingerprint and decrypted in browser RAM.';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _isLoading = false;
      });
      await _loadAttemptStatus();
    }
  }

  Map<String, dynamic> _firstRpcRow(Object? response) {
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw StateError('Courier unlock RPC returned no package data.');
  }

  bool get _canUseBackend => AppConfig.hasSupabaseConfig;

  bool get _isLocked => _attemptStatus?['locked'] == true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'FactLockCam Courier',
                    style: AppTextStyles.monoLg(color: AppColors.verifiedNeon),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock and verify an encrypted courier package locally in this browser.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _StatusPanel(
                    packageId: widget.packageId,
                    attemptStatus: _attemptStatus,
                    message: _message,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    enabled: !_isLoading && !_isLocked,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Recipient email',
                      hintText: 'name@example.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _challengeController,
                    enabled: !_isLoading && !_isLocked,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'One-time password',
                    ),
                    onSubmitted: (_) => _unlock(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isLoading || _isLocked ? null : _unlock,
                    child: _isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unlock package'),
                  ),
                  if (_verifiedBytes != null) ...[
                    const SizedBox(height: 24),
                    _VerifiedPreview(
                      bytes: _verifiedBytes!,
                      fileExtension: _fileExtension,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.packageId,
    required this.attemptStatus,
    required this.message,
  });

  final String? packageId;
  final Map<String, dynamic>? attemptStatus;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final attemptsRemaining = attemptStatus?['attempts_remaining'];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.titaniumPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.titaniumEdge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: AppTextStyles.monoSm(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PACKAGE: ${packageId ?? 'missing'}'),
              if (attemptStatus != null) ...[
                const SizedBox(height: 8),
                Text('STATUS: ${attemptStatus!['status']}'),
                Text('ATTEMPTS REMAINING: $attemptsRemaining'),
              ],
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: AppTextStyles.monoSm(color: AppColors.alertAmber),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedPreview extends StatelessWidget {
  const _VerifiedPreview({required this.bytes, required this.fileExtension});

  final Uint8List bytes;
  final String? fileExtension;

  @override
  Widget build(BuildContext context) {
    final ext = (fileExtension ?? '').replaceFirst('.', '');
    final isImage = {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(ext);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.verifiedNeon.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isImage
            ? Image.memory(bytes, fit: BoxFit.contain)
            : Text(
                'Verified ${ext.isEmpty ? 'asset' : '.$ext asset'} (${bytes.length} bytes). Preview support for this type is not enabled yet.',
                style: AppTextStyles.monoMd(),
              ),
      ),
    );
  }
}
