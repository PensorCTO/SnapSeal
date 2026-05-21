import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/ui/widgets/vault_panel_navigation_bar.dart';

/// Offline scrollable viewer for bundled legal markdown assets.
class LegalDocumentView extends StatefulWidget {
  const LegalDocumentView({
    super.key,
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;

  static const termsAssetPath = 'assets/legal/TermsOfService.md';
  static const privacyAssetPath = 'assets/legal/PrivacyPolicy.md';

  @override
  State<LegalDocumentView> createState() => _LegalDocumentViewState();
}

class _LegalDocumentViewState extends State<LegalDocumentView> {
  late final Future<String> _documentFuture =
      rootBundle.loadString(widget.assetPath);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.titaniumDeep,
      navigationBar: VaultPanelNavigationBar(
        title: widget.title,
        onBack: () => Navigator.of(context).pop(),
      ),
      child: SafeArea(
        child: FutureBuilder<String>(
          future: _documentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load document.',
                    style: AppTextStyles.monoSm(color: AppColors.alertAmber),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: SelectableText(
                snapshot.data ?? '',
                style: AppTextStyles.monoSm(
                  color: AppColors.starkWhite.withValues(alpha: 0.88),
                  height: 1.55,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
