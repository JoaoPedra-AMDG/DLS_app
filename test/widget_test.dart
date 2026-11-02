import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dls_study/app.dart';
import 'package:dls_study/models.dart';
import 'package:dls_study/visuals.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StudyStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final data =
        jsonDecode(File('assets/content.json').readAsStringSync()) as Json;
    store = StudyStore(data, await SharedPreferences.getInstance());
  });
  Future<void> launch(
    WidgetTester tester, {
    Size size = const Size(1440, 1000),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DlsApp(store: store));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Learner finds a topic, reveals a worked answer and bookmarks it',
    (tester) async {
      await launch(tester);
      expect(find.text('Your subjects'), findsOneWidget);
      await tester.tap(find.text('Find your next discovery…'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'mitosis');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mitosis & the cell cycle'));
      await tester.pumpAndSettle();
      expect(find.text('Straight from your past papers'), findsOneWidget);
      await tester.tap(find.text('Further practice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reveal worked answer').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Two daughter cells form.'), findsOneWidget);
      await tester.tap(find.byTooltip('Save topic'));
      await tester.pumpAndSettle();
      expect(store.saved, contains('t:life-mitosis-the-cell-cycle'));
      await tester.tap(find.text('Saved').first);
      await tester.pumpAndSettle();
      expect(find.text('Mitosis & the cell cycle'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Revision completion and flashcard ratings survive store reload',
    (tester) async {
      await launch(tester);
      await tester.tap(find.text('Find your next discovery…'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'circuits');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electric circuits'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revision notes'));
      await tester.pump();
      await tester.ensureVisible(find.text('Mark as revised'));
      await tester.pump();
      await tester.tap(find.text('Mark as revised'));
      await tester.pump();
      final t = store.topics.firstWhere(
        (t) => t['title'] == 'Electric circuits',
      );
      expect(store.completed, contains(t['id']));
      await tester.ensureVisible(find.text('Flashcards').last);
      await tester.tap(find.text('Flashcards').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reveal answer'));
      await tester.tap(find.text('Reveal answer'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('I remembered it'));
      await tester.tap(find.text('I remembered it'));
      await tester.pumpAndSettle();
      final reloaded = StudyStore(
        store.data,
        await SharedPreferences.getInstance(),
      );
      expect(reloaded.completed, contains(t['id']));
      expect(reloaded.known, contains('${t['id']}:0'));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Narrow phone layout and paper filters remain usable', (
    tester,
  ) async {
    await launch(tester, size: const Size(360, 800));
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Papers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All resources'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Memos').last);
    await tester.pumpAndSettle();
    expect(find.text('Open memo'), findsWidgets);
    expect(find.text('Open PDF'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('A complete flashcard review can be restarted', (tester) async {
    final t = store.topics.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FlashcardDeck(topic: t, store: store, color: purple),
          ),
        ),
      ),
    );
    for (var i = 0; i < (t['cards'] as List).length; i++) {
      await tester.tap(find.text('Reveal answer'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('I remembered it'));
      await tester.tap(find.text('I remembered it'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Study all cards'), findsOneWidget);
    await tester.tap(find.text('Study all cards'));
    await tester.pumpAndSettle();
    expect(
      find.text('CARD 1 OF ${(t['cards'] as List).length}'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Every topic illustration paints at phone width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final type in store.topics.map((t) => t['visual']).toSet()) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningVisual(
              key: ValueKey(type),
              type: type,
              color: purple,
              formula: 'Concept formula',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: type);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
