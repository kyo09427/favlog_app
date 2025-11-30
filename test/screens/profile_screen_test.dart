import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart'; // Added missing import
import 'dart:io'; // Added for File

import 'package:favlog_app/domain/models/profile.dart';
import 'package:favlog_app/domain/repositories/profile_repository.dart';
import 'package:favlog_app/domain/repositories/auth_repository.dart';
import 'package:favlog_app/presentation/providers/profile_screen_controller.dart';
import 'package:favlog_app/presentation/screens/profile_screen.dart';
import 'package:favlog_app/core/providers/profile_providers.dart'; // Import specific provider
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart'; // Corrected import for authRepositoryProvider
import 'package:favlog_app/core/providers/common_providers.dart'; // Import for imagePickerProvider
import 'package:favlog_app/main.dart'; // Keep for supabaseProvider for now

// Mock classes
class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {} // Renamed and implements SupabaseStorageClient
class MockStorageFileApi extends Mock implements StorageFileApi {}
class MockImagePicker extends Mock implements ImagePicker {}
class MockXFile extends Mock implements XFile {} // Mock for XFile

// Fallback for Profile
class FakeProfile extends Fake implements Profile {}
// Fallback for File
class FakeFile extends Fake implements File {
  final String _path;
  FakeFile([this._path = '']); // Default path to empty string
  @override
  String get path => _path;
}
// Fallback for FileOptions
class FakeFileOptions extends Fake implements FileOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProfile());
    registerFallbackValue(FakeFile()); // Register fallback for File
    registerFallbackValue(FakeFileOptions()); // Register fallback for FileOptions
  });
  
  group('ProfileScreen', () {
    late MockProfileRepository mockProfileRepository;
    late MockAuthRepository mockAuthRepository;
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;
    late MockUser mockUser;
    late MockSupabaseStorageClient mockSupabaseStorageClient; // Updated type
    late MockStorageFileApi mockStorageFileApi;
    late MockImagePicker mockImagePicker;
    late MockXFile mockXFile;

    setUp(() {
      mockProfileRepository = MockProfileRepository();
      mockAuthRepository = MockAuthRepository();
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      mockUser = MockUser();
      mockSupabaseStorageClient = MockSupabaseStorageClient(); // Updated type
      mockStorageFileApi = MockStorageFileApi();
      mockImagePicker = MockImagePicker();
      mockXFile = MockXFile();

      // Common mock setups
      when(() => mockAuthRepository.getCurrentUser()).thenReturn(mockUser); // No any() here
      when(() => mockUser.id).thenReturn('test_user_id');
      when(() => mockUser.email).thenReturn('test@example.com');
      
      when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
      when(() => mockSupabaseClient.storage).thenReturn(mockSupabaseStorageClient); // Use MockSupabaseStorageClient
      when(() => mockSupabaseStorageClient.from(any())).thenReturn(mockStorageFileApi); // Use MockSupabaseStorageClient

      // Mock XFile to return a path
      when(() => mockXFile.path).thenReturn('/test/path/to/image.jpg');
    });

    Widget createProfileScreen() {
      return ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(mockProfileRepository),
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          supabaseProvider.overrideWithValue(mockSupabaseClient),
          imagePickerProvider.overrideWithValue(mockImagePicker), // Override the imagePickerProvider
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      );
    }

    testWidgets('displays loading indicator initially (then default profile)', (tester) async {
      when(() => mockProfileRepository.fetchProfile(any()))
          .thenAnswer((_) async => null); // Simulate no profile initially, completes immediately
      when(() => mockProfileRepository.updateProfile(any()))
          .thenAnswer((_) async {}); // Mock for initial profile creation

      await tester.pumpWidget(createProfileScreen());
      // Pump to render the loading state
      await tester.pump(); // Render a frame
      expect(find.byType(Shimmer), findsOneWidget); // Assert Shimmer is present

      // Let all futures complete, including fetchProfile and createInitialProfile
      await tester.pumpAndSettle(); 

      // After settling, the shimmer should be gone and the initial profile (with default username) should be displayed
      expect(find.byType(Shimmer), findsNothing);
      expect(find.text('test'), findsOneWidget); // Expecting default username 'test' from email
    });

    testWidgets('displays existing profile data', (tester) async {
      final testProfile = Profile(
        id: 'test_user_id',
        username: 'TestUser',
        avatarUrl: 'http://example.com/avatar.jpg',
      );
      when(() => mockProfileRepository.fetchProfile(any()))
          .thenAnswer((_) async => testProfile);

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle(); // Settle all futures

      expect(find.text('TestUser'), findsOneWidget);
      expect(find.byWidgetPredicate((widget) => widget is CircleAvatar && widget.radius == 60), findsOneWidget);
      // More specific check for CachedNetworkImage could be done but requires more mocking
    });

    testWidgets('allows updating username', (tester) async {
      final initialProfile = Profile(
        id: 'test_user_id',
        username: 'OldUsername',
        avatarUrl: null,
      );
      when(() => mockProfileRepository.fetchProfile(any()))
          .thenAnswer((_) async => initialProfile);
      when(() => mockProfileRepository.updateProfile(any()))
          .thenAnswer((_) async {}); // Simulate successful update

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle();

      // Ensure initial username is displayed
      expect(find.widgetWithText(TextFormField, 'OldUsername'), findsOneWidget);

      // Enter new username
      await tester.enterText(find.byType(TextFormField), 'NewUsername');
      expect(find.text('NewUsername'), findsOneWidget);

      // Tap save button
      await tester.tap(find.text('プロフィールを保存'));
      await tester.pumpAndSettle();

      // Verify updateProfile was called with the new username
      verify(() => mockProfileRepository.updateProfile(
            any(that: isA<Profile>().having((p) => p.username, 'username', 'NewUsername')),
          )).called(1);
    });

    testWidgets('shows error when profile update fails', (tester) async {
      final initialProfile = Profile(
        id: 'test_user_id',
        username: 'OldUsername',
        avatarUrl: null,
      );
      when(() => mockProfileRepository.fetchProfile(any()))
          .thenAnswer((_) async => initialProfile);
      when(() => mockProfileRepository.updateProfile(any()))
          .thenThrow(Exception('Update failed')); // Simulate update failure

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'NewUsername');
      await tester.tap(find.text('プロフィールを保存'));
      await tester.pumpAndSettle();

      expect(find.textContaining('エラー: Exception: Update failed'), findsOneWidget);
    });

    testWidgets('allows picking and uploading avatar', (tester) async {
      final initialProfile = Profile(
        id: 'test_user_id',
        username: 'TestUser',
        avatarUrl: null,
      );
      final publicUrl = 'http://example.com/new_avatar.jpg';

      when(() => mockProfileRepository.fetchProfile(any()))
          .thenAnswer((_) async => initialProfile);
      when(() => mockProfileRepository.updateProfile(any()))
          .thenAnswer((_) async {});
      
      // Mock ImagePicker behavior
      when(() => mockImagePicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => mockXFile); // Return the mockXFile
      
      // Mock Supabase storage upload
      when(() => mockStorageFileApi.upload(any(), any(), fileOptions: any(named: 'fileOptions')))
          .thenAnswer((_) async => 'test_user_id/mock_image.jpg'); // Returns the path string
      
      
      // Mock Supabase public URL retrieval
      when(() => mockStorageFileApi.getPublicUrl(any()))
          .thenReturn(publicUrl);

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle();

      // Tap on the avatar circle
      await tester.tap(find.byWidgetPredicate((widget) => widget is CircleAvatar && widget.radius == 60));
      await tester.pumpAndSettle();

      // Verify image picker was called
      verify(() => mockImagePicker.pickImage(source: ImageSource.gallery)).called(1);

      // Verify Supabase storage upload was called
      verify(() => mockStorageFileApi.upload(
            any(that: contains('test_user_id/')),
            any(that: isA<File>()),
            fileOptions: any(named: 'fileOptions'),
          )).called(1);

      // Verify getPublicUrl was called
      verify(() => mockStorageFileApi.getPublicUrl(any())).called(1);

      // Verify profile was updated with new avatar URL
      verify(() => mockProfileRepository.updateProfile(
            any(that: isA<Profile>().having((p) => p.avatarUrl, 'avatarUrl', publicUrl)),
          )).called(1);
    });

    testWidgets('creates initial profile if none exists', (tester) async {
      when(() => mockProfileRepository.fetchProfile(any()))
          .thenAnswer((_) async => null); // No profile
      when(() => mockProfileRepository.updateProfile(any()))
          .thenAnswer((_) async {}); // Simulate successful creation

      await tester.pumpWidget(createProfileScreen());
      await tester.pumpAndSettle();

      // Because the controller tries to create an initial profile if none found
      verify(() => mockProfileRepository.updateProfile(
            any(that: isA<Profile>()
                .having((p) => p.id, 'id', 'test_user_id')
                .having((p) => p.username, 'username', 'test') // default from email
            ),
          )).called(1);
    });
  });
}
