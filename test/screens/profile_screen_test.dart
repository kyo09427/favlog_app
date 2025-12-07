import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'dart:typed_data';


import 'package:favlog_app/domain/models/profile.dart';
import 'package:favlog_app/core/services/image_compressor.dart';
import 'package:favlog_app/domain/repositories/profile_repository.dart';
import 'package:favlog_app/domain/repositories/auth_repository.dart';
import 'package:favlog_app/domain/repositories/review_repository.dart';
import 'package:favlog_app/domain/repositories/product_repository.dart';
import 'package:favlog_app/domain/repositories/comment_repository.dart';
import 'package:favlog_app/domain/repositories/like_repository.dart';
import 'package:favlog_app/presentation/screens/profile_screen.dart';
import 'package:favlog_app/core/providers/profile_providers.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';
import 'package:favlog_app/data/repositories/supabase_review_repository.dart';
import 'package:favlog_app/data/repositories/supabase_product_repository.dart';
import 'package:favlog_app/data/repositories/supabase_comment_repository.dart';
import 'package:favlog_app/data/repositories/supabase_like_repository.dart';
import 'package:favlog_app/core/providers/common_providers.dart';
import 'package:favlog_app/main.dart';

// Mock classes
class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockReviewRepository extends Mock implements ReviewRepository {}
class MockProductRepository extends Mock implements ProductRepository {}
class MockCommentRepository extends Mock implements CommentRepository {}
class MockLikeRepository extends Mock implements LikeRepository {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}
class MockStorageFileApi extends Mock implements StorageFileApi {}
class MockImagePicker extends Mock implements ImagePicker {}
class MockXFile extends Mock implements XFile {}
class MockImageCompressor extends Mock implements ImageCompressor {}

// Fallback values
class FakeProfile extends Fake implements Profile {}
class FakeFile extends Fake implements File {
  final String _path;
  FakeFile([this._path = '']);
  @override
  String get path => _path;
}
class FakeFileOptions extends Fake implements FileOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProfile());
    registerFallbackValue(FakeFile());
    registerFallbackValue(FakeFileOptions());
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(ImageSource.gallery);
  });
  
  group('ProfileScreen', () {
    late MockProfileRepository mockProfileRepository;
    late MockAuthRepository mockAuthRepository;
    late MockReviewRepository mockReviewRepository;
    late MockProductRepository mockProductRepository;
    late MockCommentRepository mockCommentRepository;
    late MockLikeRepository mockLikeRepository;
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;
    late MockUser mockUser;
    late MockSupabaseStorageClient mockSupabaseStorageClient;
    late MockStorageFileApi mockStorageFileApi;
    late MockImagePicker mockImagePicker;
    late MockXFile mockXFile;
    late MockImageCompressor mockImageCompressor;

    setUp(() {
      mockProfileRepository = MockProfileRepository();
      mockAuthRepository = MockAuthRepository();
      mockReviewRepository = MockReviewRepository();
      mockProductRepository = MockProductRepository();
      mockCommentRepository = MockCommentRepository();
      mockLikeRepository = MockLikeRepository();
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      mockUser = MockUser();
      mockSupabaseStorageClient = MockSupabaseStorageClient();
      mockStorageFileApi = MockStorageFileApi();
      mockImagePicker = MockImagePicker();
      mockXFile = MockXFile();
      mockImageCompressor = MockImageCompressor();

      // Common mock setups
      when(() => mockAuthRepository.getCurrentUser()).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('test_user_id');
      when(() => mockUser.email).thenReturn('test@example.com');
      
      when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
      when(() => mockSupabaseClient.storage).thenReturn(mockSupabaseStorageClient);
      when(() => mockSupabaseStorageClient.from(any())).thenReturn(mockStorageFileApi);

      when(() => mockXFile.path).thenReturn('/test/path/to/image.jpg');
      when(() => mockXFile.readAsBytes()).thenAnswer((_) async => Uint8List.fromList([10, 20, 30]));
      
      // Mock review, product, comment, like repositories to return empty data
      when(() => mockReviewRepository.getReviewsByUserId(any())).thenAnswer((_) async => []);
      when(() => mockLikeRepository.getAllUserLikedReviewIds(any())).thenAnswer((_) async => []);
    });

    Widget createProfileScreen() {
      return ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(mockProfileRepository),
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          reviewRepositoryProvider.overrideWithValue(mockReviewRepository),
          productRepositoryProvider.overrideWithValue(mockProductRepository),
          commentRepositoryProvider.overrideWithValue(mockCommentRepository),
          likeRepositoryProvider.overrideWithValue(mockLikeRepository),
          supabaseProvider.overrideWithValue(mockSupabaseClient),
          imagePickerProvider.overrideWithValue(mockImagePicker),
          imageCompressorProvider.overrideWithValue(mockImageCompressor),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      );
    }

    testWidgets('displays loading indicator initially', (tester) async {
      when(() => mockProfileRepository.fetchProfile(any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Profile(id: 'test_user_id', username: 'TestUser', displayId: 'testuser');
      });

      await tester.pumpWidget(createProfileScreen());

      // 初期状態でローディングインジケーターが表示されることを確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(); 

      // ローディング完了後、プロフィールが表示されることを確認
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('TestUser'), findsOneWidget);
    });

    testWidgets('displays existing profile data', (tester) async {
      final testProfile = Profile(
        id: 'test_user_id',
        username: 'TestUser',
        displayId: 'testuser',
        avatarUrl: 'http://example.com/avatar.jpg',
      );
      when(() => mockProfileRepository.fetchProfile(any())).thenAnswer((_) async => testProfile);

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle();

      // ユーザー名の表示を確認
      expect(find.text('TestUser'), findsOneWidget);
      // ハンドルネームの表示を確認
      expect(find.text('@testuser'), findsOneWidget);
      // タブの表示を確認（複数あるので findsWidgets を使用）
      expect(find.text('レビュー'), findsWidgets);
      expect(find.text('いいね'), findsWidgets);
    });

    testWidgets('allows updating username via edit dialog', (tester) async {
      final initialProfile = Profile(id: 'test_user_id', username: 'OldUsername', displayId: 'old_id');
      when(() => mockProfileRepository.fetchProfile(any())).thenAnswer((_) async => initialProfile);
      when(() => mockProfileRepository.updateProfile(any())).thenAnswer((_) async {});

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle();

      // 初期のユーザー名が表示されることを確認
      expect(find.text('OldUsername'), findsOneWidget);

      // 編集ボタンをタップして編集ダイアログを開く
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // 編集ダイアログが表示されることを確認
      expect(find.text('プロフィールを編集'), findsOneWidget);

      // ユーザー名を変更
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));
      final usernameField = textFields.first;
      await tester.enterText(usernameField, 'NewUsername');
      
      // 保存ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // updateProfileが呼ばれたことを確認
      verify(() => mockProfileRepository.updateProfile(
            any(that: isA<Profile>().having((p) => p.username, 'username', 'NewUsername')),
          )).called(1);
    });

    testWidgets('shows error when profile update fails', (tester) async {
      final initialProfile = Profile(id: 'test_user_id', username: 'TestUser', displayId: 'testuser');
      when(() => mockProfileRepository.fetchProfile(any())).thenAnswer((_) async => initialProfile);
      when(() => mockProfileRepository.updateProfile(any())).thenThrow(Exception('Update failed'));

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle();

      // 編集ボタンをタップ
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // ユーザー名を変更
      await tester.enterText(find.byType(TextField).first, 'FailedUpdate');
      
      // 保存ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pump();
      
      // updateProfileが呼ばれたことを確認（エラーが発生する）
      verify(() => mockProfileRepository.updateProfile(
            any(that: isA<Profile>().having((p) => p.username, 'username', 'FailedUpdate')),
          )).called(1);
    });

    testWidgets('allows picking and uploading avatar via edit dialog', (tester) async {
      final initialProfile = Profile(id: 'test_user_id', username: 'TestUser', displayId: 'testuser');
      final publicUrl = 'http://example.com/new_avatar.webp';
      final compressedBytes = Uint8List.fromList([1, 2, 3]);

      when(() => mockProfileRepository.fetchProfile(any())).thenAnswer((_) async => initialProfile);
      when(() => mockProfileRepository.updateProfile(any())).thenAnswer((_) async {});
      
      when(() => mockImagePicker.pickImage(
        source: any(named: 'source'),
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality'),
      )).thenAnswer((_) async => mockXFile);

      when(() => mockImageCompressor.compressImage(
        any(),
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        quality: any(named: 'quality'),
      )).thenAnswer((_) async => compressedBytes);
      
      when(() => mockStorageFileApi.uploadBinary(
        any(),
        any(),
        fileOptions: any(named: 'fileOptions')
      )).thenAnswer((_) async => '');
      
      when(() => mockStorageFileApi.getPublicUrl(any())).thenReturn(publicUrl);

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle();

      // 編集ボタンをタップして編集ダイアログを開く
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // 編集ダイアログ内のアバター変更ボタンをタップ
      await tester.tap(find.text('プロフィール画像を変更'));
      await tester.pumpAndSettle();

      // 画像選択、圧縮、アップロードが実行されたことを確認
      verify(() => mockImagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality')
      )).called(1);

      verify(() => mockImageCompressor.compressImage(
        any(),
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        quality: any(named: 'quality'),
      )).called(1);

      verify(() => mockStorageFileApi.uploadBinary(
            any(that: contains('.webp')),
            compressedBytes,
            fileOptions: any(named: 'fileOptions', that: isA<FileOptions>().having((fo) => fo.contentType, 'contentType', 'image/webp')),
          )).called(1);

      verify(() => mockStorageFileApi.getPublicUrl(any(that: contains('.webp')))).called(1);

      verify(() => mockProfileRepository.updateProfile(
            any(that: isA<Profile>().having((p) => p.avatarUrl, 'avatarUrl', publicUrl)),
          )).called(1);
    });

    testWidgets('creates initial profile if none exists', (tester) async {
      when(() => mockProfileRepository.fetchProfile(any())).thenAnswer((_) async => null);
      when(() => mockProfileRepository.updateProfile(any())).thenAnswer((_) async {});

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle();

      // 初期プロフィールが作成されることを確認
      verify(() => mockProfileRepository.updateProfile(
            any(that: isA<Profile>()
                .having((p) => p.id, 'id', 'test_user_id')
                .having((p) => p.username, 'username', 'test')
            ),
          )).called(1);
      
      // デフォルトのユーザー名が表示されることを確認
      expect(find.text('test'), findsOneWidget);
    });
  });
}
