import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// StatefulShellRouteと共に使用するナビゲーションバーを持つScaffold
class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  // ナビゲーションシェル。UIの構築とブランチ間の移動に使用
  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ブランチ（タブ）がタップされたときに呼び出される
  void _onTap(int index) {
    if (index == 1 && !_isAnimating) {
      setState(() {
        _isAnimating = true;
      });
      _animationController.forward().then((_) {
        _animationController.reset();
        setState(() {
          _isAnimating = false;
        });
      });
    }
    // goBranchを使用して、現在のブランチのナビゲーション状態を維持したまま
    // 別のブランチに移動する。
    //
    // saveState: false の場合、新しいブランチに移動するたびに
    // そのブランチの初期ロケーションにリセットされる。
    widget.navigationShell.goBranch(
      index,
      // navigationShell.currentIndex == index の場合でも
      // スタックの最初のページに移動するため、initialLocation: true を設定
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final animation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: ScaleTransition(
              scale: animation,
              child: const Icon(Icons.search),
            ),
            label: '検索',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'プロフィール',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
        currentIndex: widget.navigationShell.currentIndex,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true, // ラベルを表示する
        showUnselectedLabels: true,
      ),
    );
  }
}
