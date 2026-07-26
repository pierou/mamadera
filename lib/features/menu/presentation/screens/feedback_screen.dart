import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/app_config.dart';
import '../../../../../core/l10n/app_localizations_extension.dart';
import '../../../../../core/theme.dart';

/// Feedback screen for submitting bug reports or feature ideas.
///
/// Users compose a title and description, choose a type (Bug or Idea),
/// and submit via GitHub Issues (browser) or email (mailto:).
/// Device info is auto-appended to the body for bug triage.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'bug';
  bool _titleError = false;
  bool _descriptionError = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty;

  /// Builds the device info footer string.
  String _buildDeviceInfo() {
    return '---\n'
        'App ${AppConfig.version} · '
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }

  /// Builds the full body text with device info appended.
  String _buildBody() {
    final description = _descriptionController.text.trim();
    final deviceInfo = _buildDeviceInfo();
    return '$description\n\n$deviceInfo';
  }

  /// Builds the subject/title string with type prefix.
  String _buildSubject() {
    final typePrefix = _type == 'bug' ? '[Bug]' : '[Idea]';
    return '$typePrefix ${_titleController.text.trim()}';
  }

  /// Launches the GitHub Issues page with pre-filled title and body.
  Future<void> _submitViaGitHub() async {
    _validateFields();
    if (!_canSubmit) return;

    final subject = _buildSubject();
    final body = _buildBody();
    final uri = Uri.parse(AppConfig.githubIssuesUrl)
        .replace(queryParameters: {
          'title': subject,
          'body': body,
        });

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showLaunchError();
    }
  }

  /// Launches the email app with pre-filled subject and body.
  Future<void> _submitViaEmail() async {
    _validateFields();
    if (!_canSubmit) return;

    final subject = _buildSubject();
    final body = _buildBody();
    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.contactEmail,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    if (!await launchUrl(uri)) {
      _showLaunchError();
    }
  }

  void _validateFields() {
    _titleError = _titleController.text.trim().isEmpty;
    _descriptionError = _descriptionController.text.trim().isEmpty;
    setState(() {});
  }

  void _clearFieldError(String field) {
    setState(() {
      if (field == 'title') _titleError = false;
      if (field == 'description') _descriptionError = false;
    });
  }

  void _showLaunchError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l.feedbackLaunchError)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.feedbackTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            Text(
              l.feedbackTypeLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildTypeSelector(context, colorScheme),
            const SizedBox(height: AppTheme.spacingXxl),

            // Title field
            Text(
              l.feedbackTitleLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: l.feedbackTitleHint,
                errorText: _titleError ? l.feedbackValidationTitle : null,
                border: const OutlineInputBorder(),
              ),
              maxLines: 1,
              maxLength: 100,
              onChanged: (_) => _clearFieldError('title'),
            ),
            const SizedBox(height: AppTheme.spacingXxl),

            // Description field
            Text(
              l.feedbackDescriptionLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: l.feedbackDescriptionHint,
                errorText:
                    _descriptionError ? l.feedbackValidationDescription : null,
                border: const OutlineInputBorder(),
              ),
              maxLines: 6,
              onChanged: (_) => _clearFieldError('description'),
            ),
            const SizedBox(height: AppTheme.spacingXxl),

            // Device info footer (read-only)
            Text(
              _buildDeviceInfo(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXxl),

            // Submit buttons
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canSubmit ? _submitViaGitHub : null,
                icon: const Icon(Icons.code),
                label: Text(l.feedbackSubmitGitHub),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.spacingXs),
              child: Text(
                l.feedbackGitHubHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _canSubmit ? _submitViaEmail : null,
                icon: const Icon(Icons.email_outlined),
                label: Text(l.feedbackSubmitEmail),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context, ColorScheme colorScheme) {
    final l = context.l;
    return Row(
      children: [
        Expanded(
          child: _buildTypeTile(
            context,
            'bug',
            Icons.bug_report_outlined,
            l.feedbackTypeBug,
            colorScheme,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: _buildTypeTile(
            context,
            'idea',
            Icons.lightbulb_outline,
            l.feedbackTypeError,
            colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeTile(
    BuildContext context,
    String value,
    IconData icon,
    String label,
    ColorScheme colorScheme,
  ) {
    final isSelected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingMd,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingXs),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
