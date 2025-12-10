// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categoryRepositoryHash() =>
    r'a7b3c8d9e6f1g2h3i4j5k6l7m8n9o0p1q2r3s4t5';

/// See also [categoryRepository].
@ProviderFor(categoryRepository)
final categoryRepositoryProvider =
    AutoDisposeProvider<CategoryRepository>.internal(
  categoryRepository,
  name: r'categoryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$categoryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CategoryRepositoryRef = AutoDisposeProviderRef<CategoryRepository>;
String _$popularKeywordsHash() => r'b8c9d0e1f2g3h4i5j6k7l8m9n0o1p2q3r4s5t6u7';

/// See also [popularKeywords].
@ProviderFor(popularKeywords)
final popularKeywordsProvider =
    AutoDisposeFutureProvider<List<String>>.internal(
  popularKeywords,
  name: r'popularKeywordsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$popularKeywordsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PopularKeywordsRef = AutoDisposeFutureProviderRef<List<String>>;
