import 'package:flutter/widgets.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// Monospaced legal copy block for sheets and dialogs.
class LegalDisclosureText extends StatelessWidget {
  const LegalDisclosureText(
    this.text, {
    super.key,
    this.opacity = 0.85,
    this.textAlign,
  });

  final String text;
  final double opacity;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: AppTextStyles.monoSm(
        color: AppColors.starkWhite.withValues(alpha: opacity),
        height: 1.4,
      ),
    );
  }
}

/// Scrollable column of [paragraphs] with consistent spacing.
class LegalDisclosureColumn extends StatelessWidget {
  const LegalDisclosureColumn({
    super.key,
    required this.paragraphs,
    this.opacity = 0.85,
    this.textAlign,
    this.spacing = 12,
  });

  final List<String> paragraphs;
  final double opacity;
  final TextAlign? textAlign;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < paragraphs.length; i++) {
      if (i > 0) {
        children.add(SizedBox(height: spacing));
      }
      children.add(
        LegalDisclosureText(
          paragraphs[i],
          opacity: opacity,
          textAlign: textAlign,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
