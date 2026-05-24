import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/core/utils/error_handler.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  void _copyText(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ErrorHandler.showSuccess(context, '$label copied');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact Us',
          style: TextStyle(color: isDark ? Colors.white : AppTheme.textPrimaryLight),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We are here to help.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'For support, contact us at the email below.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _contactTile(
            context,
            icon: CupertinoIcons.mail_solid,
            title: 'Email',
            value: 'contact@buuttii.com',
            isDark: isDark,
            onCopy: () => _copyText(context, 'Email', 'contact@buuttii.com'),
          ),
          const SizedBox(height: 20),
          Text(
            'Tap Copy to use this email anywhere you want.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onCopy,
            icon: const Icon(CupertinoIcons.doc_on_doc, size: 16),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
