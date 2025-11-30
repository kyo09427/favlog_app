import 'package:flutter/material.dart';

class CommonBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CommonBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: Colors.grey[600],
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'フィード',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: '検索',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'プロフィール',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: '設定',
        ),
      ],
    );
  }
}

// ナビゲーションヘルパー
class NavigationHelper {
  static void navigateToIndex(BuildContext context, int index, int currentIndex) {
    if (index == currentIndex) return;

    // ナビゲーションスタックをクリアして目的の画面に遷移
    switch (index) {
      case 0:
        // ホーム画面 - スタックをクリアしてルートに戻る
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        break;
      case 1:
        // 検索画面
        if (currentIndex == 0) {
          // ホームから検索へ - 新しいルートとしてプッシュ
          Navigator.of(context).pushNamed('/search');
        } else {
          // 他の画面から検索へ - 現在の画面を置き換え
          Navigator.of(context).pushReplacementNamed('/search');
        }
        break;
      case 2:
        // プロフィール画面
        if (currentIndex == 0) {
          // ホームからプロフィールへ - 新しいルートとしてプッシュ
          Navigator.of(context).pushNamed('/profile');
        } else {
          // 他の画面からプロフィールへ - 現在の画面を置き換え
          Navigator.of(context).pushReplacementNamed('/profile');
        }
        break;
      case 3:
        // 設定画面（未実装）
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定機能は準備中です')),
        );
        break;
    }
  }
}