import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/app_config.dart';
import '../../../../../core/l10n/app_localizations_extension.dart';
import '../../../../../core/theme.dart';

/// App information and attributions screen.
///
/// Displays app version, description, third-party credits (Flaticon splash icon),
/// and license info with links to the GitHub repository.
class InfoScreen extends ConsumerWidget {
  const InfoScreen({super.key});

  /// Flaticon attribution URL for the splash icon.
  static const String _flaticonUrl =
      'https://www.flaticon.com/fr/icones-gratuites/enfant-et-bebe';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.aboutTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info Section
            _buildSection(context, l.aboutVersionLabel, AppConfig.version),

            const SizedBox(height: AppTheme.spacingLg),

            // Description
            Text(
              l.aboutDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
            ),

            // Attributions Section
            const SizedBox(height: AppTheme.spacingXxl),
            _buildSectionTitle(l.aboutAttributionsSectionTitle, context),

            const SizedBox(height: AppTheme.spacingMd),
            ListTile(
              leading: Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant),
              title: Text(l.aboutFlaticonCredit),
              subtitle: RichText(
                text: TextSpan(
                  style: TextStyle(color: colorScheme.primary, fontSize: 13),
                  children: [
                    const TextSpan(text: '( '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => _launchUrl(context, _flaticonUrl),
                        child: Text(
                          'enfant-et-bebe.flaticon.com',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' )'),
                  ],
                ),
              ),
            ),

            // License Section
            const SizedBox(height: AppTheme.spacingXxl),
            _buildSectionTitle(l.aboutLicenseLabel, context),

            const SizedBox(height: AppTheme.spacingMd),
            ListTile(
              leading: Icon(Icons.code_outlined, color: colorScheme.onSurfaceVariant),
              title: Text(l.aboutLicenseLabel),
              trailing: Icon(Icons.open_in_new, size: 18, color: colorScheme.onSurfaceVariant),
              onTap: () => _launchUrl(context, 'https://github.com/pierou/mamadera'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: AppTheme.spacingSm),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
