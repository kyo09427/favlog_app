import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// StatefulShellRouteと共に使用するナビゲーションバーを持つScaffold
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  // ナビゲーションシェル。UIの構築とブランチ間の移動に使用
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '検索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'プロフィール',
          ),
        ],
        currentIndex: navigationShell.currentIndex,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true, // ラベルを表示する
        showUnselectedLabels: true,
      ),
    );
  }

  // ブランチ（タブ）がタップされたときに呼び出される
  void _onTap(int index) {
    // goBranchを使用して、現在のブランチのナビゲーション状態を維持したまま
    // 別のブランチに移動する。
    //
    // saveState: false の場合、新しいブランチに移動するたびに
    // そのブランチの初期ロケーションにリセットされる。
    navigationShell.goBranch(
      index,
      // navigationShell.currentIndex == index の場合でも
      // スタックの最初のページに移動するため、initialLocation: true を設定
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
