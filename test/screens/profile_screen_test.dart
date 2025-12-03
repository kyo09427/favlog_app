import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:favlog_app/domain/models/profile.dart';
import 'package:favlog_app/core/services/image_compressor.dart';
import 'package:favlog_app/domain/repositories/profile_repository.dart';
import 'package:favlog_app/domain/repositories/auth_repository.dart';
import 'package:favlog_app/presentation/providers/profile_screen_controller.dart';
import 'package:favlog_app/presentation/screens/profile_screen.dart';
import 'package:favlog_app/core/providers/profile_providers.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';
import 'package:favlog_app/core/providers/common_providers.dart';
import 'package:favlog_app/main.dart';

// Mock classes
class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
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
  });
  
  group('ProfileScreen', () {
    late MockProfileRepository mockProfileRepository;
    late MockAuthRepository mockAuthRepository;
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
    });

    Widget createProfileScreen() {
      return ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(mockProfileRepository),
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          supabaseProvider.overrideWithValue(mockSupabaseClient),
          imagePickerProvider.overrideWithValue(mockImagePicker),
          imageCompressorProvider.overrideWithValue(mockImageCompressor),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      );
    }

    testWidgets('displays loading indicator initially (then default profile)', (tester) async {
      when(() => mockProfileRepository.fetchProfile(any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10)); // Simulate network delay
        return null;
      });
      when(() => mockProfileRepository.updateProfile(any())).thenAnswer((_) async {});

      await tester.pumpWidget(createProfileScreen());

      expect(find.byType(Shimmer), findsOneWidget); // Check for loading state immediately

      await tester.pumpAndSettle(); 

      expect(find.byType(Shimmer), findsNothing);
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('displays existing profile data', (tester) async {
      final testProfile = Profile(
        id: 'test_user_id',
        username: 'TestUser',
        avatarUrl: 'http://example.com/avatar.jpg',
      );
      when(() => mockProfileRepository.fetchProfile(any())).thenAnswer((_) async => testProfile);

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('TestUser'), findsOneWidget);
      expect(find.byWidgetPredicate((widget) => widget is CircleAvatar && widget.radius == 60), findsOneWidget);
    });

    testWidgets('allows updating username', (tester) async {
      final initialProfile = Profile(id: 'test_user_id', username: 'OldUsername');
      when(() => mockProfileRepository.fetchProfile(any())).thenAnswer((_) async => initialProfile);
      when(() => mockProfileRepository.updateProfile(any())).thenAnswer((_) async {});

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'OldUsername'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'NewUsername');
      await tester.tap(find.text('プロフィールを保存'));
      await tester.pumpAndSettle();

      verify(() => mockProfileRepository.updateProfile(
            any(that: isA<Profile>().having((p) => p.username, 'username', 'NewUsername')),
          )).called(1);
    });

    testWidgets('shows error when profile update fails', (tester) async {
      final initialProfile = Profile(id: 'test_user_id', username: 'OldUsername');
      when(() => mockProfileRepository.fetchProfile(any())).thenAnswer((_) async => initialProfile);
      when(() => mockProfileRepository.updateProfile(any())).thenThrow(Exception('Update failed'));

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'NewUsername');
      await tester.tap(find.text('プロフィールを保存'));
      await tester.pumpAndSettle(); // Let the controller update its state and listener to fire
      await tester.pump(); // Pump again to show the dialog

      // The error is shown in a dialog
      expect(find.text('エラー'), findsOneWidget); // The dialog title
      expect(find.text('プロフィールの更新に失敗しました: Exception: Update failed'), findsOneWidget);
    });

    testWidgets('allows picking and uploading avatar', (tester) async {
      final initialProfile = Profile(id: 'test_user_id', username: 'TestUser');
      final publicUrl = 'http://example.com/new_avatar.webp';
      final compressedBytes = Uint8List.fromList([1, 2, 3]);

      when(() => mockProfileRepository.fetchProfile(any())).thenAnswer((_) async => initialProfile);
      when(() => mockProfileRepository.updateProfile(any())).thenAnswer((_) async {});
      
      when(() => mockImagePicker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85))
          .thenAnswer((_) async => mockXFile);
      
      when(() => mockImageCompressor.compressWithFile(
        any(), minWidth: 512, minHeight: 512, quality: 80, format: CompressFormat.webp,
      )).thenAnswer((_) async => compressedBytes);
      
      when(() => mockStorageFileApi.uploadBinary(any(), any(), fileOptions: any(named: 'fileOptions')))
          .thenAnswer((_) async => '');
      
      when(() => mockStorageFileApi.getPublicUrl(any())).thenReturn(publicUrl);

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byWidgetPredicate((widget) => widget is CircleAvatar && widget.radius == 60));
      await tester.pumpAndSettle();

      verify(() => mockImagePicker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85)).called(1);

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

      verify(() => mockProfileRepository.updateProfile(
            any(that: isA<Profile>()
                .having((p) => p.id, 'id', 'test_user_id')
                .having((p) => p.username, 'username', 'test')
            ),
          )).called(1);
    });
  });
}
