import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final backgroundColor = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    const primaryColor = Color(0xFF13EC5B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          '設定',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            context,
            title: 'アカウント',
            children: [
              _buildSettingsItem(
                context,
                title: 'パスワードを変更',
                icon: Icons.lock_outline,
                onTap: () {
                  context.push('/password-reset-request');
                },
                primaryColor: primaryColor,
                textColor: textColor,
                mutedTextColor: mutedTextColor,
              ),
              _buildSettingsItem(
                context,
                title: 'メールアドレスを変更',
                icon: Icons.email_outlined,
                onTap: () {
                  context.push('/update-email-request');
                },
                primaryColor: primaryColor,
                textColor: textColor,
                mutedTextColor: mutedTextColor,
              ),
            ],
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: children
                .map((item) => Column(
                      children: [
                        item,
                        if (item != children.last)
                          Divider(
                            color: borderColor,
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: mutedTextColor, size: 18),
          ],
        ),
      ),
    );
  }
}
