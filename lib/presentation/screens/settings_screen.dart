import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // go_routerのために追加

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundDark = Color(0xFF102216);
    const itemBackground = Color(0xFF1C271F);
    const borderColor = Color(0xFF3B5443);
    const primaryColor = Color(0xFF13EC5B);
    const textColor = Colors.white;
    const mutedTextColor = Color(0xFF9DB9A6);

    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        title: const Text(
          '設定',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundDark,
        elevation: 0,
        automaticallyImplyLeading: false, // ScaffoldWithNavBarを使用しているため不要
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
              ),
              _buildSettingsItem(
                context,
                title: 'メールアドレスを変更',
                icon: Icons.email_outlined,
                onTap: () {
                  context.push('/update-email-request');
                },
                primaryColor: primaryColor,
              ),
              // 他のアカウント設定項目
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    const textColor = Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C271F), // itemBackground
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3B5443)), // borderColor
          ),
          child: Column(
            children: children
                .map((item) => Column(
                      children: [
                        item,
                        if (item != children.last)
                          const Divider(
                            color: Color(0xFF3B5443), // borderColor
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
  }) {
    const textColor = Colors.white;
    const mutedTextColor = Color(0xFF9DB9A6);

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
                style: const TextStyle(color: textColor, fontSize: 16),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: mutedTextColor, size: 18),
          ],
        ),
      ),
    );
  }
}

