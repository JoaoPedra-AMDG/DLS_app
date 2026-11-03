import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dls_study/app.dart';
import 'package:dls_study/models.dart';
import 'package:dls_study/visuals.dart';
import 'package:dls_study/pdf_reader_screen.dart';
import 'package:dls_study/focus_timer.dart';

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
      await tester.ensureVisible(find.text('Reveal answer'));
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

  testWidgets('Challenge questions reveal their worked solutions', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.text('Find your next discovery…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'circuits');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Electric circuits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Challenge questions'));
    await tester.pumpAndSettle();
    expect(find.text('CHALLENGE 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Reveal worked answer').first);
    await tester.tap(find.text('Reveal worked answer').first);
    await tester.pumpAndSettle();
    final t = store.topics.firstWhere((t) => t['title'] == 'Electric circuits');
    expect(find.text(t['challenges'][0]['answer']), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDF reader keeps Back and Download available on a phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var downloads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => PdfReaderScreen(
                                  uri: Uri.parse(
                                    'https://study.test/paper.pdf',
                                  ),
                                  title: 'November Paper 1 · 2024',
                                  filename: 'paper.pdf',
                                  onDownload: () async {
                                    downloads++;
                                    return true;
                                  },
                                ),
                          ),
                        ),
                    child: const Text('Read paper'),
                  ),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('Read paper'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(downloads, 1);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Read paper'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Students can find platform-specific install instructions', (
    tester,
  ) async {
    await launch(tester, size: const Size(390, 844));
    await tester.ensureVisible(find.text('Install For Rosa'));
    await tester.tap(find.text('Install For Rosa'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Install For Rosa'),
      ),
      findsOneWidget,
    );
    expect(find.text('Android · Chrome'), findsOneWidget);
    expect(find.text('iPhone or iPad · Safari'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pomodoro survives navigation and supports pauses and breaks', (
    tester,
  ) async {
    await launch(tester, size: const Size(390, 844));
    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();
    expect(find.text('Your focus space'), findsOneWidget);
    await tester.ensureVisible(find.text('Start / continue'));
    await tester.tap(find.text('Start / continue'));
    await tester.pump();
    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();
    expect(find.text('Pause'), findsOneWidget);
    await tester.ensureVisible(find.text('Pause'));
    await tester.tap(find.text('Pause'));
    await tester.pump();
    await tester.ensureVisible(find.text('Short break · 5 min'));
    await tester.tap(find.text('Short break · 5 min'));
    await tester.pump();
    expect(find.text('05:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Pomodoro deadline catches up and counts a completed session once',
    (tester) async {
      var now = DateTime(2026, 11, 3, 10);
      final session = FocusSession(clock: () => now);
      addTearDown(session.dispose);
      session.toggle();
      now = now.add(const Duration(minutes: 24, seconds: 59));
      await tester.pump(const Duration(seconds: 1));
      expect(session.seconds, 1);
      now = now.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(session.seconds, 0);
      expect(session.running, isFalse);
      expect(session.completed, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(session.completed, 1);
    },
  );

  testWidgets(
    'Wave frequency and amplitude are independent and reset together',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningVisual(
              type: 'wave',
              color: purple,
              formula: 'v = fλ',
            ),
          ),
        ),
      );
      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(2));
      tester.widget<Slider>(sliders.at(1)).onChanged!(2);
      await tester.pump();
      expect(tester.widget<Slider>(sliders.first).value, 1);
      expect(find.textContaining('wavelength 0.50×'), findsOneWidget);
      tester.widget<Slider>(sliders.first).onChanged!(1.5);
      await tester.pump();
      expect(tester.widget<Slider>(sliders.at(1)).value, 2);
      await tester.tap(find.text('Reset visual'));
      await tester.pump();
      expect(tester.widget<Slider>(sliders.first).value, 1);
      expect(tester.widget<Slider>(sliders.at(1)).value, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Classroom files can be searched within their own library', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.text('Classroom files').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('classroom-search')),
      'Eucharistic',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Eucharistic Miracles Assignment Grade 10 2026'),
      findsOneWidget,
    );
    expect(find.text('Read PDF'), findsOneWidget);
    expect(find.text('Download DOCX'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'School links are labelled and excluded by the local-files filter',
    (tester) async {
      final demo = Map<String, dynamic>.from(store.data);
      demo['classroom'] = [
        ...store.documents,
        {
          'id': 'school-fixture',
          'subject': 'physical',
          'subjects': ['physical'],
          'title': 'Example school worksheet',
          'kind': 'worksheet',
          'format': 'PDF',
          'availability': 'school',
          'sourceUrl': 'https://drive.google.com/',
          'sourceIds': ['fixture'],
          'sourceLinks': [
            {'url': 'https://drive.google.com/', 'label': 'First posting'},
            {'url': 'https://docs.google.com/', 'label': 'Second posting'},
          ],
          'sections': ['Example'],
        },
      ];
      final demoStore = StudyStore(demo, store.prefs);
      await tester.binding.setSurfaceSize(const Size(1440, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(DlsApp(store: demoStore));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Classroom files').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('classroom-search')),
        'Example school worksheet',
      );
      await tester.pumpAndSettle();
      expect(find.text('Open school document'), findsOneWidget);
      expect(find.text('Read PDF'), findsNothing);
      await tester.tap(find.text('All 2 posted copies'));
      await tester.pumpAndSettle();
      expect(find.text('First posting'), findsOneWidget);
      expect(find.text('Second posting'), findsOneWidget);
      await tester.tap(find.text('Files available in For Rosa'));
      await tester.pumpAndSettle();
      expect(find.text('Open school document'), findsNothing);
      expect(
        find.text('No documents match. Try another search or type.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
