import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // セグメントボタン用
  final List<String> _filters = ['すべて', '商品', 'サービス', 'ユーザー'];
  int _selectedFilterIndex = 0;

  // とりあえずダミーデータ（あとで Supabase / Riverpod に接続してOK）
  List<String> _searchHistory = [
    'オーガニックコーヒー',
    'ワイヤレスイヤホン',
    '新宿 カフェ',
  ];

  final List<String> _popularKeywords = [
    '#キャンプ',
    '#ガジェット',
    '#インテリア',
    '#手土産',
    '#子育てグッズ',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onClearAllHistory() {
    setState(() {
      _searchHistory.clear();
    });
  }

  void _onRemoveHistoryItem(int index) {
    setState(() {
      _searchHistory.removeAt(index);
    });
  }

  void _onTapHistoryItem(String keyword) {
    setState(() {
      _searchController.text = keyword;
    });
    // TODO: keyword で検索実行したければここで呼ぶ
  }

  void _onTapPopularKeyword(String keyword) {
    setState(() {
      _searchController.text = keyword.replaceFirst('#', '');
    });
    // TODO: keyword で検索実行したければここで呼ぶ
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // HTMLの「arrow_back + 中央タイトル」に近い感じのAppBar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'レビュー検索',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '商品、サービス、タグ、ユーザー名で検索',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                    ),
                    onChanged: (value) {
                      // TODO: デバウンス検索したければここで
                    },
                  ),
                ),
              ),

              // Segmented Buttons（すべて / 商品 / サービス / ユーザー）
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: List.generate(_filters.length, (index) {
                      final selected = _selectedFilterIndex == index;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilterIndex = index;
                              });
                              // TODO: 絞り込み検索するならここで
                            },
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: selected
                                    ? (theme.brightness == Brightness.dark
                                        ? Colors.grey[900]
                                        : Colors.white)
                                    : Colors.transparent,
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _filters[index],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: selected
                                      ? (theme.brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black87)
                                      : (theme.brightness ==
                                              Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.grey[700]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 検索履歴
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '検索履歴',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_searchHistory.isNotEmpty)
                      TextButton(
                        onPressed: _onClearAllHistory,
                        child: const Text('すべてクリア'),
                      ),
                  ],
                ),
              ),
              if (_searchHistory.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    '検索履歴はありません',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchHistory.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final keyword = _searchHistory[index];
                    return InkWell(
                      onTap: () => _onTapHistoryItem(keyword),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                keyword,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              onPressed: () => _onRemoveHistoryItem(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 16),

              // 人気のキーワード
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  '人気のキーワード',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _popularKeywords.map((keyword) {
                    return GestureDetector(
                      onTap: () => _onTapPopularKeyword(keyword),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.green.withOpacity(0.15),
                        ),
                        child: Text(
                          keyword,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.green[600],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
