import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  final List<String> _filters = ['すべて', '商品', 'サービス', 'ユーザー'];

  final List<String> _popularKeywords = [
    '#キャンプ',
    '#ガジェット',
    '#インテリア',
    '#手土産',
    '#子育てグッズ',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onClearAllHistory() {
    ref.read(searchControllerProvider.notifier).clearAllHistory();
  }

  void _onRemoveHistoryItem(int index) {
    ref.read(searchControllerProvider.notifier).removeHistoryItem(index);
  }

  void _onTapHistoryItem(String keyword) {
    _searchController.text = keyword;
    ref.read(searchControllerProvider.notifier).searchFromHistory(keyword);
  }

  void _onTapPopularKeyword(String keyword) {
    final cleanKeyword = keyword.replaceFirst('#', '');
    _searchController.text = cleanKeyword;
    ref.read(searchControllerProvider.notifier).updateSearchQuery(cleanKeyword);
  }

  void _onClearSearch() {
    _searchController.clear();
    ref.read(searchControllerProvider.notifier).clearSearch();
  }

  Widget _buildThumbnail(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 80,
        child: imageUrl == null
            ? Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image),
              ),
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        
        IconData icon;
        if (rating >= starIndex) {
          icon = Icons.star;
        } else if (rating >= starIndex - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        
        return Icon(
          icon,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  Widget _buildSearchResultItem(SearchResult result) {
    final product = result.product;
    final latestReview = result.latestReview;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        context.push('/product/${product.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(product.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product.category != null || product.subcategory != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (product.category != null)
                          Chip(
                            label: Text(
                              product.category!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.8),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        if (product.subcategory != null)
                          Chip(
                            label: Text(
                              product.subcategory!,
                              style: theme.textTheme.bodySmall,
                            ),
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                      ],
                    ),
                  if (latestReview != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStarRating(latestReview.rating),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            latestReview.reviewText,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchControllerProvider);
    final searchController = ref.read(searchControllerProvider.notifier);

    if (_searchController.text != searchState.searchQuery) {
      _searchController.text = searchState.searchQuery;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // leadingを削除して戻るボタンを非表示に
        automaticallyImplyLeading: false,
        title: const Text(
          'レビュー検索',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '商品、サービス、タグ、ユーザー名で検索',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchState.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _onClearSearch,
                          )
                        : null,
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
                    searchController.updateSearchQuery(value);
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    final selected = searchState.selectedFilter == _filters[index];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: GestureDetector(
                          onTap: () {
                            searchController.selectFilter(_filters[index]);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
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
                                    : (theme.brightness == Brightness.dark
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

            Expanded(
              child: searchState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : searchState.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'エラーが発生しました',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                searchState.error!,
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : searchState.searchResults.isNotEmpty
                          ? ListView.builder(
                              itemCount: searchState.searchResults.length,
                              itemBuilder: (context, index) {
                                return _buildSearchResultItem(
                                  searchState.searchResults[index],
                                );
                              },
                            )
                          : searchState.searchQuery.isNotEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('検索結果が見つかりませんでした'),
                                    ],
                                  ),
                                )
                              : _buildHistoryAndKeywords(theme, searchState),
            ),
          ],
        ),
      ),

    );
  }

  Widget _buildHistoryAndKeywords(ThemeData theme, SearchScreenState searchState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '検索履歴',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (searchState.searchHistory.isNotEmpty)
                  TextButton(
                    onPressed: _onClearAllHistory,
                    child: const Text('すべてクリア'),
                  ),
              ],
            ),
          ),
          if (searchState.searchHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '検索履歴はありません',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: searchState.searchHistory.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final keyword = searchState.searchHistory[index];
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '人気のキーワード',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
    );
  }
}