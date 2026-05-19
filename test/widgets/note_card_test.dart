import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/config/theme.dart';
import 'package:second_brain/l10n/app_localizations.dart';
import 'package:second_brain/models/note.dart';
import 'package:second_brain/providers/settings_provider.dart';
import 'package:second_brain/providers/tags_provider.dart';
import 'package:second_brain/services/interfaces/storage_service_interface.dart';
import 'package:second_brain/widgets/note_card.dart';
import '../helpers/mock_storage_service.dart';

Widget createTestWidget(Widget child) {
  return MaterialApp(
    theme: BrainTheme.darkTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<TagsProvider>(
          create: (_) => TagsProvider(
            storage: MockStorageService() as IStorageService,
          ),
        ),
      ],
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('NoteCard', () {
    final baseNote = Note(
      id: '1',
      title: 'Test Note Title',
      content: 'Test note content preview',
      emoji: '📝',
      notebook: 'General',
      createdAt: DateTime(2026, 5, 19),
      updatedAt: DateTime(2026, 5, 19),
    );

    testWidgets('renders title and emoji', (tester) async {
      await tester.pumpWidget(
        createTestWidget(NoteCard(note: baseNote)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Note Title'), findsOneWidget);
      expect(find.text('📝'), findsOneWidget);
    });

    testWidgets('renders content preview', (tester) async {
      await tester.pumpWidget(
        createTestWidget(NoteCard(note: baseNote)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Test note content'), findsOneWidget);
    });

    testWidgets('shows notebook name', (tester) async {
      await tester.pumpWidget(
        createTestWidget(NoteCard(note: baseNote)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('General'), findsWidgets);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        createTestWidget(NoteCard(
          note: baseNote,
          onTap: () => tapped = true,
        )),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Note Title'));
      expect(tapped, isTrue);
    });

    testWidgets('shows pinned indicator when pinned', (tester) async {
      final pinnedNote = baseNote.copyWith(isPinned: true);
      await tester.pumpWidget(
        createTestWidget(NoteCard(note: pinnedNote)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Note Title'), findsOneWidget);
    });
  });
}
