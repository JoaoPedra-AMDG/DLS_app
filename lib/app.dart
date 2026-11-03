import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'pdf_reader_screen.dart';
import 'platform_actions.dart' as platform;
import 'models.dart';
import 'visuals.dart';
import 'focus_timer.dart';

void main() => runApp(const DlsApp());

class DlsApp extends StatefulWidget {
  const DlsApp({super.key, this.store});
  final StudyStore? store;
  @override
  State<DlsApp> createState() => _DlsAppState();
}

class _DlsAppState extends State<DlsApp> {
  late final Future<StudyStore> loaded =
      widget.store == null ? StudyStore.load() : Future.value(widget.store);
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'For Rosa',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
        surface: Colors.white,
      ),
      fontFamily: 'Roboto',
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Color(0xFFE3E0ED)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E6F0)),
        ),
      ),
    ),
    home: FutureBuilder<StudyStore>(
      future: loaded,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 44),
                    const SizedBox(height: 16),
                    const Text(
                      'The study library could not load. Please reload the page.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      '${snapshot.error}',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return StudyShell(store: snapshot.data!);
      },
    ),
  );
}

class StudyShell extends StatefulWidget {
  const StudyShell({super.key, required this.store});
  final StudyStore store;
  @override
  State<StudyShell> createState() => _StudyShellState();
}

class _StudyShellState extends State<StudyShell> {
  String nav = 'Overview';
  String? subjectId;
  Json? topic;
  int subjectTab = 0, topicTab = 0;
  String year = 'All years', kind = 'All resources', division = 'All';
  String classroomQuery = '', classroomKind = 'All types';
  bool classroomLocalOnly = false;
  int classroomLimit = 24;
  final scroll = ScrollController();
  final focusSession = FocusSession();
  StudyStore get store => widget.store;
  @override
  void dispose() {
    focusSession.dispose();
    scroll.dispose();
    super.dispose();
  }

  void go(String target) {
    setState(() {
      nav = target;
      classroomQuery = '';
      classroomKind = 'All types';
      classroomLocalOnly = false;
      classroomLimit = 24;
      subjectId = null;
      topic = null;
      year = 'All years';
      kind = 'All resources';
      division = 'All';
    });
    top();
  }

  void top() {
    if (scroll.hasClients) {
      scroll.jumpTo(0);
    }
  }

  void openSubject(String id, {int tab = 0}) {
    setState(() {
      subjectId = id;
      topic = null;
      subjectTab = tab;
      classroomLimit = 24;
      classroomQuery = '';
      classroomKind = 'All types';
      classroomLocalOnly = false;
      year = 'All years';
      kind = 'All resources';
      division = 'All';
      nav = 'My subjects';
    });
    top();
  }

  void openTopic(Json t, {int tab = 0}) {
    store.rememberTopic(t['id']);
    setState(() {
      topic = t;
      subjectId = t['subject'];
      topicTab = tab;
      nav = 'My subjects';
    });
    top();
  }

  Uri paperUri(Json p) {
    final path = 'assets/assets/papers/${p['file']}';
    return (kIsWeb
        ? Uri.base.replace(fragment: '', query: '').resolve(path)
        : Uri.parse('https://joaopedra-amdg.github.io/DLS_app/$path'));
  }

  Future<void> openPaper(Json p, {int? page}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => PdfReaderScreen(
              uri: paperUri(p),
              title: p['title'],
              filename: p['file'],
              page: page ?? 1,
            ),
      ),
    );
  }

  Future<void> downloadPaper(Json p) async {
    try {
      if (!await platform.downloadPdf(paperUri(p), p['file']) && mounted) {
        notice('The PDF could not download. Please try again.');
      }
    } catch (_) {
      if (mounted) {
        notice(
          'The PDF could not download. Check your connection and try again.',
        );
      }
    }
  }

  Future<void> downloadOriginal(Json document) async {
    final path = 'assets/assets/classroom/${document['originalFile']}';
    final uri =
        kIsWeb
            ? Uri.base.replace(fragment: '', query: '').resolve(path)
            : Uri.parse('https://joaopedra-amdg.github.io/DLS_app/$path');
    try {
      if (!await platform.downloadPdf(uri, document['originalName']) &&
          mounted) {
        notice('This file could not download. Please try again.');
      }
    } catch (_) {
      if (mounted) notice('Check your connection and try again.');
    }
  }

  Future<void> openSchoolFile(Json document) async {
    try {
      if (!await platform.openExternal(Uri.parse(document['sourceUrl'])) &&
          mounted) {
        notice('The school document could not open. Please try again.');
      }
    } catch (_) {
      if (mounted) {
        notice('Open this document from your school Classroom account.');
      }
    }
  }

  void notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder:
        (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1050;
            return Scaffold(
              drawer:
                  wide
                      ? null
                      : Drawer(
                        backgroundColor: Colors.white,
                        child: SafeArea(child: sidebar(drawer: true)),
                      ),
              bottomNavigationBar:
                  wide
                      ? null
                      : NavigationBar(
                        selectedIndex:
                            nav == 'Overview'
                                ? 0
                                : nav == 'Pomodoro'
                                ? 4
                                : nav == 'Saved'
                                ? 3
                                : nav == 'Past papers'
                                ? 2
                                : 1,
                        onDestinationSelected:
                            (i) => go(
                              [
                                'Overview',
                                'My subjects',
                                'Past papers',
                                'Saved',
                                'Pomodoro',
                              ][i],
                            ),
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.grid_view_rounded),
                            label: 'Home',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.auto_stories_outlined),
                            label: 'Subjects',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.description_outlined),
                            label: 'Papers',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.bookmark_border_rounded),
                            label: 'Saved',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.timer_outlined),
                            label: 'Focus',
                          ),
                        ],
                      ),
              body: SafeArea(
                child: Row(
                  children: [
                    if (wide) SizedBox(width: 224, child: sidebar()),
                    Expanded(
                      child: Column(
                        children: [
                          header(wide),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scroll,
                              padding: EdgeInsets.fromLTRB(
                                wide ? 38 : 20,
                                24,
                                wide ? 38 : 20,
                                40,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1320,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (store.persistenceError != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: Text(
                                            store.persistenceError!,
                                            style: const TextStyle(
                                              color: Colors.deepOrange,
                                            ),
                                          ),
                                        ),
                                      if (topic != null)
                                        topicPage(topic!)
                                      else if (subjectId != null)
                                        subjectPage(store.subject(subjectId!))
                                      else if (nav == 'Overview')
                                        dashboard()
                                      else if (nav == 'My subjects')
                                        subjectsPage()
                                      else if (nav == 'Past papers')
                                        allPapers()
                                      else if (nav == 'Classroom files')
                                        classroomLibrary()
                                      else if (nav == 'Flashcards')
                                        flashcardsPage()
                                      else if (nav == 'Pomodoro')
                                        FocusScreen(session: focusSession)
                                      else
                                        savedPage(),
                                      const SizedBox(height: 34),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 6,
                                        children: [
                                          const Text(
                                            'For Rosa · Grade 10',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: muted,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: showAbout,
                                            child: const Text(
                                              'About this library',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: purple,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
  );
  Widget sidebar({bool drawer = false}) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(right: BorderSide(color: Color(0xFFEAE8F0))),
    ),
    padding: const EdgeInsets.fromLTRB(19, 32, 19, 22),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              if (drawer) {
                Navigator.pop(context);
              }
              go('Overview');
            },
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: purple,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'For Rosa',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: -.8,
                        ),
                      ),
                      Text(
                        'YOUR STUDY SPACE',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.only(left: 13, bottom: 12),
            child: Text(
              'YOUR WORKSPACE',
              style: TextStyle(
                fontSize: 9,
                color: muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          for (final (name, icon) in [
            ('Overview', Icons.grid_view_rounded),
            ('My subjects', Icons.auto_stories_outlined),
            ('Past papers', Icons.description_outlined),
            ('Classroom files', Icons.folder_copy_outlined),
            ('Flashcards', Icons.style_outlined),
            ('Pomodoro', Icons.timer_outlined),
            ('Saved', Icons.bookmark_border_rounded),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Material(
                color:
                    nav == name ? const Color(0xFFEFECFC) : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () {
                    if (drawer) {
                      Navigator.pop(context);
                    }
                    go(name);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 19,
                          color: nav == name ? purple : muted,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  nav == name
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              color: nav == name ? purple : muted,
                            ),
                          ),
                        ),
                        if (name == 'Saved' && store.saved.isNotEmpty) ...[
                          Text(
                            '${store.saved.length}',
                            style: const TextStyle(fontSize: 11, color: purple),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.only(left: 13, bottom: 12),
            child: Text(
              'MY SUBJECTS',
              style: TextStyle(
                fontSize: 9,
                color: muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              for (final s in store.subjects)
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 13),
                  minLeadingWidth: 9,
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: subjectColor(s),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    s['name'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          subjectId == s['id']
                              ? FontWeight.w700
                              : FontWeight.w400,
                    ),
                  ),
                  onTap: () {
                    if (drawer) {
                      Navigator.pop(context);
                    }
                    openSubject(s['id']);
                  },
                ),
            ],
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFFECE9FA),
                child: Icon(Icons.person_outline, size: 19, color: purple),
              ),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My study space',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Progress saved on this device',
                      style: TextStyle(fontSize: 9, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  Widget header(bool wide) => Container(
    height: 82,
    padding: EdgeInsets.symmetric(horizontal: wide ? 38 : 16),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFEAE8F0))),
    ),
    child: Row(
      children: [
        if (!wide)
          Builder(
            builder:
                (ctx) => IconButton(
                  tooltip: 'Open navigation',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                ),
          ),
        if (wide) ...[
          Text(
            topic != null
                ? 'Learning studio'
                : subjectId != null
                ? 'My subjects'
                : nav,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
        ],
        Expanded(
          flex: wide ? 0 : 1,
          child: SizedBox(
            width: wide ? 310 : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: search,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: canvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEDF4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: muted, size: 19),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search subjects, topics and papers',
                        style: TextStyle(fontSize: 12, color: muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        const Pill(text: 'GRADE 10', color: purple),
      ],
    ),
  );
  Widget dashboard() => LayoutBuilder(
    builder: (context, bounds) {
      final right = bounds.maxWidth > 1000;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'AMDG',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.9,
                  ),
                ),
              ),
              if (bounds.maxWidth > 550)
                Text(
                  dateLabel(),
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    hero(),
                    const SizedBox(height: 28),
                    sectionTitle('Your subjects', ''),
                    const SizedBox(height: 16),
                    subjectGrid(),
                    const SizedBox(height: 28),
                    sectionTitle('Study tools', ''),
                    const SizedBox(height: 15),
                    studyModes(),
                    const SizedBox(height: 26),
                    continueCard(),
                  ],
                ),
              ),
              if (right) ...[
                const SizedBox(width: 25),
                SizedBox(
                  width: 258,
                  child: Column(
                    children: [
                      progressPanel(),
                      const SizedBox(height: 20),
                      focusShortcut(),
                      const SizedBox(height: 20),
                      tipPanel(),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (!right) ...[
            const SizedBox(height: 24),
            LayoutBuilder(
              builder:
                  (context, b) =>
                      b.maxWidth > 620
                          ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: progressPanel()),
                              const SizedBox(width: 18),
                              Expanded(child: focusShortcut()),
                            ],
                          )
                          : Column(
                            children: [
                              progressPanel(),
                              const SizedBox(height: 18),
                              focusShortcut(),
                            ],
                          ),
            ),
          ],
          const SizedBox(height: 28),
          panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Install the app',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add your study space to your home screen. Open a PDF once online to keep a copy available offline.',
                  style: TextStyle(color: muted, height: 1.6),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: install,
                  icon: const Icon(Icons.install_mobile_rounded),
                  label: const Text('Install For Rosa'),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
  Widget focusShortcut() => panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.timer_outlined, color: purple),
        const SizedBox(height: 12),
        const Text(
          'Pomodoro timer',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          '25-minute focus sessions with short and long breaks.',
          style: TextStyle(color: muted, height: 1.6),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () => go('Pomodoro'),
          child: const Text('Open Pomodoro'),
        ),
      ],
    ),
  );
  Widget hero() => FilledButton.icon(
    onPressed: () => go('My subjects'),
    icon: const Icon(Icons.arrow_forward_rounded, size: 17),
    label: const Text('Open subjects'),
  );
  Widget sectionTitle(String title, String sub) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -.4,
              ),
            ),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(sub, style: const TextStyle(fontSize: 12, color: muted)),
            ],
          ],
        ),
      ),
      if (title == 'Your subjects')
        TextButton(
          onPressed: () => go('My subjects'),
          child: const Text('View all →', style: TextStyle(fontSize: 11)),
        ),
    ],
  );
  Widget subjectGrid() => LayoutBuilder(
    builder: (context, b) {
      final cols =
          b.maxWidth > 1100
              ? 5
              : b.maxWidth > 600
              ? 3
              : b.maxWidth > 410
              ? 2
              : 1;
      final width = (b.maxWidth - 16 * (cols - 1)) / cols;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final s in store.subjects)
            SizedBox(width: width, child: subjectCard(s)),
        ],
      );
    },
  );
  Widget subjectCard(Json s) {
    final ts = store.subjectTopics(s['id']);
    final done = ts.where((t) => store.completed.contains(t['id'])).length;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => openSubject(s['id']),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEAE8F1)),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: subjectLight(s),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      subjectIcon(s['id']),
                      color: subjectColor(s),
                      size: 25,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: subjectColor(s),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                s['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${ts.length} topics · ${store.subjectPapers(s['id']).where((p) => p['kind'] == 'paper').length} papers',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: ts.isEmpty ? 0 : done / ts.length,
                  minHeight: 4,
                  color: subjectColor(s),
                  backgroundColor: subjectLight(s),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                done == 0
                    ? '0 of ${ts.length} topics revised'
                    : '$done of ${ts.length} topics revised',
                style: const TextStyle(fontSize: 10, color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget studyModes() => LayoutBuilder(
    builder: (context, b) {
      final cols = b.maxWidth > 570 ? 4 : 2;
      final w = (b.maxWidth - 12 * (cols - 1)) / cols;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final (title, icon, index) in [
            ('Past papers', Icons.description_outlined, 0),
            ('Topic questions', Icons.edit_note_rounded, 1),
            ('Revision notes', Icons.auto_stories_outlined, 2),
            ('Flashcards', Icons.style_outlined, 3),
          ])
            SizedBox(
              width: w,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => chooseSubject(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 8,
                    ),
                    child: Column(
                      children: [
                        Icon(icon, size: 25, color: purple),
                        const SizedBox(height: 11),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
  Widget continueCard() {
    final previous =
        store.topics.where((t) => t['id'] == store.lastTopic).firstOrNull;
    return panel(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5DF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFFBD8C38),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  previous == null ? 'Choose a topic' : 'Continue studying',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  previous?['title'] ?? 'Select a subject to choose a topic.',
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: previous == null ? 'Explore topics' : 'Continue topic',
            onPressed:
                () =>
                    previous == null ? go('My subjects') : openTopic(previous),
            icon: const Icon(Icons.arrow_forward_rounded, color: purple),
          ),
        ],
      ),
    );
  }

  Widget progressPanel() {
    final n = store.completed.length, total = store.topics.length;
    return panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Progress',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.route_outlined, size: 19, color: purple),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 124,
              height: 124,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: total == 0 ? 0 : n / total,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      color: purple,
                      backgroundColor: const Color(0xFFEFECFA),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$n',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'topics revised',
                        style: TextStyle(fontSize: 10, color: muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 23),
          Text(
            '$total topics to explore. Mark notes as revised when you feel confident.',
            style: const TextStyle(fontSize: 11, color: muted, height: 1.7),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.style_outlined, size: 18, color: purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${store.known.length} cards remembered',
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget tipPanel() => panel(
    color: const Color(0xFFEAF5EF),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.spa_outlined, color: Color(0xFF30836A)),
        SizedBox(height: 13),
        Text(
          'Study tip',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 9),
        Text(
          'Close your notes and explain an idea out loud. Then check what you missed.',
          style: TextStyle(fontSize: 12, height: 1.8, color: muted),
        ),
      ],
    ),
  );
  Widget panel({required Widget child, Color color = Colors.white}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAE8F0)),
        ),
        child: child,
      );
  Widget subjectsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      pageHeading('Subjects', 'Choose a subject and topic.'),
      const SizedBox(height: 25),
      subjectGrid(),
      const SizedBox(height: 28),
      studyModes(),
    ],
  );
  Widget pageHeading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 28,
          letterSpacing: -.8,
          height: 1.25,
        ),
      ),
      if (subtitle.isNotEmpty) ...[
        const SizedBox(height: 9),
        Text(
          subtitle,
          style: const TextStyle(color: muted, fontSize: 13, height: 1.7),
        ),
      ],
    ],
  );
  Widget subjectPage(Json s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      back('All subjects', () => go('My subjects')),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: subjectLight(s),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(subjectIcon(s['id']), color: subjectColor(s), size: 44),
            const SizedBox(width: 18),
            Expanded(child: pageHeading(s['name'], '')),
          ],
        ),
      ),
      const SizedBox(height: 25),
      tabs(
        [
          'Past papers',
          'Topic questions',
          'Revision notes',
          'Flashcards',
          'Classroom files',
        ],
        subjectTab,
        (i) => setState(() => subjectTab = i),
        color: subjectColor(s),
      ),
      const SizedBox(height: 24),
      if (subjectTab == 0)
        paperLibrary(subject: s)
      else if (subjectTab == 4)
        classroomLibrary(subject: s)
      else ...[
        pageHeading(
          subjectTab == 1
              ? 'Topic questions'
              : subjectTab == 2
              ? 'Revision notes'
              : 'Flashcards',
          subjectTab == 1
              ? 'Original exam pages, matching memos, and extra questions with worked answers.'
              : subjectTab == 2
              ? 'Clear explanations, key formulae and visual ideas for every topic.'
              : 'Choose a topic to flip, recall, and track what you remember.',
        ),
        const SizedBox(height: 23),
        if (subjectTab == 3)
          subjectFlashcards(s['id'])
        else
          topicList(store.subjectTopics(s['id']), mode: subjectTab),
      ],
    ],
  );
  Widget back(String text, VoidCallback action) => TextButton.icon(
    onPressed: action,
    style: TextButton.styleFrom(padding: EdgeInsets.zero),
    icon: const Icon(Icons.arrow_back_rounded, size: 16),
    label: Text(text, style: const TextStyle(fontSize: 12)),
  );
  Widget tabs(
    List<String> labels,
    int selected,
    ValueChanged<int> change, {
    Color color = purple,
  }) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (int i = 0; i < labels.length; i++)
        ChoiceChip(
          label: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected == i ? Colors.white : muted,
              ),
            ),
          ),
          selected: selected == i,
          showCheckmark: false,
          selectedColor: color,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: selected == i ? color : const Color(0xFFE4E1ED),
          ),
          onSelected: (_) => change(i),
        ),
    ],
  );
  Widget topicList(List<Json> ts, {int mode = 1}) => Column(
    children: [
      for (final group in ts.map(topicGroup).toSet()) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 10),
            child: Text(
              group.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: muted,
                letterSpacing: 1.3,
              ),
            ),
          ),
        ),
        for (final t in ts.where((t) => topicGroup(t) == group))
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: topicRow(t, mode),
          ),
      ],
    ],
  );
  Widget topicRow(Json t, int mode) {
    final s = store.subject(t['subject']);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap:
            () => openTopic(
              t,
              tab:
                  mode == 3
                      ? 3
                      : mode == 2
                      ? 2
                      : 0,
            ),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8E6EF)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: subjectLight(s),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  store.completed.contains(t['id'])
                      ? Icons.check_rounded
                      : mode == 3
                      ? Icons.style_outlined
                      : mode == 2
                      ? Icons.auto_stories_outlined
                      : Icons.edit_note_rounded,
                  color: subjectColor(s),
                  size: 21,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      mode == 3
                          ? '${(t['cards'] as List?)?.length ?? 0} cards'
                          : mode == 2
                          ? '${t['minutes']} min read · visual revision'
                          : '${(t['sources'] as List).length} exam selections · ${(t['practice'] as List).length} extra questions',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip:
                    store.saved.contains('t:${t['id']}')
                        ? 'Unsave topic'
                        : 'Save topic',
                onPressed: () => store.toggleSaved('t:${t['id']}'),
                icon: Icon(
                  store.saved.contains('t:${t['id']}')
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: subjectColor(s),
                  size: 21,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget allPapers() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      pageHeading(
        'The past-paper library',
        'Original DLS papers, organised by subject, paper and year.',
      ),
      const SizedBox(height: 24),
      paperLibrary(),
    ],
  );
  Widget paperLibrary({Json? subject}) {
    final ps =
        (subject == null ? store.papers : store.subjectPapers(subject['id']))
            .where((p) => p['kind'] != 'unavailable')
            .toList()
          ..sort((a, b) => (b['year'] ?? 0).compareTo(a['year'] ?? 0));
    final years =
        ps
            .map((p) => p['year']?.toString() ?? 'Year not stated')
            .toSet()
            .toList();
    final filtered =
        ps
            .where(
              (p) =>
                  (year == 'All years' ||
                      (p['year']?.toString() ?? 'Year not stated') == year) &&
                  (kind == 'All resources' ||
                      p['kind'] ==
                          (kind == 'Papers'
                              ? 'paper'
                              : kind == 'Memos'
                              ? 'memo'
                              : 'supplement')) &&
                  (division == 'All' ||
                      (subject == null
                          ? p['subject'] == division
                          : p['title'].contains(division))),
            )
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            dropdown('Year', year, [
              'All years',
              ...years,
            ], (v) => setState(() => year = v)),
            dropdown('Resource', kind, [
              'All resources',
              'Papers',
              'Memos',
              'Question booklets',
            ], (v) => setState(() => kind = v)),
            if (subject == null)
              dropdown(
                'Subject',
                division,
                ['All', ...store.subjects.map((s) => s['id'] as String)],
                (v) => setState(() => division = v),
                labels: {for (final s in store.subjects) s['id']: s['name']},
              )
            else if (subject['id'] == 'physical')
              dropdown('Discipline', division, [
                'All',
                'Physics',
                'Chemistry',
              ], (v) => setState(() => division = v)),
          ],
        ),
        const SizedBox(height: 19),
        Text(
          '${filtered.length} resources · Read in the app or download a copy',
          style: const TextStyle(fontSize: 12, color: muted),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          empty(
            'No resources match these filters.',
            'Try another year or resource type.',
            Icons.filter_alt_off_outlined,
          ),
        for (final p in filtered)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: paperRow(p),
          ),
        const SizedBox(height: 12),
        panel(
          color: const Color(0xFFFFF8E8),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: Color(0xFFAA7B27),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '44 uploads reviewed. Four exact duplicates are combined. Two blank PDFs are excluded from study results. Unknown years and missing memos are labelled.',
                  style: TextStyle(fontSize: 12, height: 1.7, color: muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChange, {
    Map<dynamic, dynamic>? labels,
  }) => SizedBox(
    width: 195,
    child: DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: const TextStyle(fontSize: 12),
      ),
      items:
          items
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    labels?[i] ?? i,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
              .toList(),
      onChanged: (v) {
        if (v != null) {
          onChange(v);
        }
      },
    ),
  );
  Widget paperRow(Json p) {
    final s = store.subject(p['subject']);
    final isMemo = p['kind'] == 'memo';
    return panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: subjectLight(s),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isMemo
                      ? Icons.fact_check_outlined
                      : Icons.picture_as_pdf_outlined,
                  color: subjectColor(s),
                  size: 23,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          s['name'],
                          style: TextStyle(
                            fontSize: 10,
                            color: subjectColor(s),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Pill(
                          text:
                              isMemo
                                  ? 'MEMO'
                                  : p['kind'] == 'supplement'
                                  ? 'QUESTION BOOKLET'
                                  : 'PAPER',
                          color: subjectColor(s),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${p['pages']} pages · Original PDF',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip:
                    store.saved.contains('p:${p['id']}')
                        ? 'Unsave resource'
                        : 'Save resource',
                onPressed: () => store.toggleSaved('p:${p['id']}'),
                icon: Icon(
                  store.saved.contains('p:${p['id']}')
                      ? Icons.bookmark
                      : Icons.bookmark_border_rounded,
                  color: subjectColor(s),
                ),
              ),
            ],
          ),
          if ((p['note'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                p['note'],
                style: const TextStyle(fontSize: 11, color: muted, height: 1.6),
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => openPaper(p),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
                label: Text(
                  isMemo ? 'Open memo' : 'Open PDF',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              TextButton.icon(
                onPressed: () => downloadPaper(p),
                icon: const Icon(Icons.download_rounded, size: 17),
                label: const Text(
                  'Download PDF',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              if (p['memo'] != null)
                TextButton.icon(
                  onPressed: () => openPaper(store.paper(p['memo'])),
                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                  label: const Text(
                    'Matching memo',
                    style: TextStyle(fontSize: 12),
                  ),
                )
              else if (p['kind'] == 'paper')
                const Text(
                  'Memo not supplied',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget topicPage(Json t) {
    final s = store.subject(t['subject']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        back(s['name'], () => setState(() => topic = null)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            Pill(
              text: (s['name'] as String).toUpperCase(),
              color: subjectColor(s),
            ),
            Pill(text: topicGroup(t).toUpperCase(), color: muted),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: pageHeading(t['title'], '')),
            IconButton(
              tooltip:
                  store.saved.contains('t:${t['id']}')
                      ? 'Unsave topic'
                      : 'Save topic',
              onPressed: () => store.toggleSaved('t:${t['id']}'),
              icon: Icon(
                store.saved.contains('t:${t['id']}')
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: subjectColor(s),
              ),
            ),
          ],
        ),
        const SizedBox(height: 23),
        tabs(
          [
            'Exam questions',
            'Further practice',
            'Revision notes',
            'Flashcards',
            'Challenge questions',
          ],
          topicTab,
          (i) => setState(() => topicTab = i),
          color: subjectColor(s),
        ),
        const SizedBox(height: 25),
        if (topicTab == 0)
          originalQuestions(t)
        else if (topicTab == 1)
          practice(t)
        else if (topicTab == 2)
          revision(t, s)
        else if (topicTab == 3)
          FlashcardDeck(
            key: ValueKey(t['id']),
            topic: t,
            store: store,
            color: subjectColor(s),
          )
        else
          practice(t, challenge: true),
      ],
    );
  }

  Widget originalQuestions(Json t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Straight from your past papers',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
      ),
      const SizedBox(height: 9),
      const Text(
        'Open the selected page for the original question, equations and diagrams. Read the complete question and any preceding source passage. Links use PDF file page numbers.',
        style: TextStyle(color: muted, fontSize: 12, height: 1.8),
      ),
      const SizedBox(height: 20),
      if ((t['sources'] as List).isEmpty)
        const Text(
          'Use the linked Classroom worksheets and teaching material below, then try the further practice and concept challenges.',
          style: TextStyle(color: muted, height: 1.7),
        ),
      if (store.topicDocuments(t).isNotEmpty) ...[
        const Text(
          'From your Classroom',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          title: Text(
            'Classroom worksheets and notes (${store.topicDocuments(t).length})',
            style: const TextStyle(fontSize: 14),
          ),
          initiallyExpanded: (t['sources'] as List).isEmpty,
          children: [
            for (final document in store.topicDocuments(t))
              classroomRow(document),
          ],
        ),
        const SizedBox(height: 20),
      ],
      for (final r in List<Json>.from(t['sources']))
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['label'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${store.paper(r['paper'])['title']} · PDF page ${r['page']}',
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed:
                          () => openPaper(
                            store.paper(r['paper']),
                            page: r['page'],
                          ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text(
                        'Open question page',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    if (r['memo'] != null)
                      OutlinedButton.icon(
                        onPressed:
                            () => openPaper(
                              store.paper(r['memo']),
                              page: r['memoPage'],
                            ),
                        icon: const Icon(Icons.fact_check_outlined, size: 16),
                        label: Text(
                          r['memoPage'] != null
                              ? 'Memo · PDF page ${r['memoPage']}'
                              : 'Open matching memo',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
                if (r['memo'] == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'No original memo was supplied for this paper. Worked answers belong to the new practice questions.',
                      style: TextStyle(fontSize: 11, color: muted, height: 1.6),
                    ),
                  ),
                if (r['memo'] != null &&
                    (store.paper(r['memo'])['note'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      store.paper(r['memo'])['note'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: muted,
                        height: 1.6,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      TextButton(
        onPressed: () => setState(() => topicTab = 1),
        child: const Text('Further practice →'),
      ),
    ],
  );
  Widget practice(Json t, {bool challenge = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Pill(
        text:
            challenge
                ? 'CONCEPT CHALLENGES · EXPLAIN YOUR THINKING'
                : 'NEW PRACTICE · GENERATED STUDY MATERIAL',
        color: purple,
      ),
      const SizedBox(height: 13),
      Text(
        challenge ? 'Concept challenges' : 'Practice questions',
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Text(
        challenge
            ? 'Predict what changes, explain why, and test a claim with an example or counterexample. These challenges test your understanding of the ideas, not just a longer calculation. Try before revealing the suggested reasoning. Generated study material.'
            : 'Work it out first. Reveal the worked answer when you’re ready. These are original practice questions inspired by the topic, not official exam questions.',
        style: const TextStyle(fontSize: 12, color: muted, height: 1.8),
      ),
      const SizedBox(height: 21),
      for (final (i, q)
          in List<Json>.from(t[challenge ? 'challenges' : 'practice']).indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 17),
          child: panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${challenge ? 'CHALLENGE' : 'QUESTION'} ${i + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: purple,
                  ),
                ),
                const SizedBox(height: 13),
                SelectableText(
                  q['question'],
                  style: const TextStyle(fontSize: 16, height: 1.7),
                ),
                const SizedBox(height: 17),
                ExpansionTile(
                  key: ValueKey(
                    '${t['id']}-${challenge ? 'challenge' : 'question'}-$i',
                  ),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                  title: const Text(
                    'Reveal worked answer',
                    style: TextStyle(
                      fontSize: 13,
                      color: purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        q['answer'],
                        style: const TextStyle(fontSize: 14, height: 1.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ],
  );
  Widget revision(Json t, Json s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Pill(
        text: 'GENERATED REVISION · CHECK YOUR UNDERSTANDING',
        color: purple,
      ),
      const SizedBox(height: 20),
      LearningVisual(
        key: ValueKey(t['id']),
        type: t['visual'],
        color: subjectColor(s),
        formula: t['formula'],
      ),
      if (store.topicDocuments(t).isNotEmpty)
        ExpansionTile(
          title: const Text(
            'Classroom sources for this topic',
            style: TextStyle(fontSize: 14),
          ),
          subtitle: const Text(
            'Read the teaching notes and original worksheets',
          ),
          children: [for (final d in store.topicDocuments(t)) classroomRow(d)],
        ),
      const SizedBox(height: 22),
      for (final (i, n) in List<Json>.from(t['notes']).indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: panel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: subjectLight(s),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: subjectColor(s),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['heading'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        n['body'],
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.9,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      panel(
        color: const Color(0xFFFFF6E1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exam tip',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 9),
            Text(
              t['tip'],
              style: const TextStyle(fontSize: 13, height: 1.8, color: muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Wrap(
        spacing: 15,
        runSpacing: 15,
        children: [
          FilledButton.icon(
            onPressed: () => store.toggleComplete(t['id']),
            icon: Icon(
              store.completed.contains(t['id'])
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
              size: 18,
            ),
            label: Text(
              store.completed.contains(t['id'])
                  ? 'Revised · tap to undo'
                  : 'Mark as revised',
            ),
          ),
          OutlinedButton(
            onPressed: () => setState(() => topicTab = 3),
            child: const Text('Test yourself with flashcards →'),
          ),
        ],
      ),
    ],
  );
  Widget classroomLibrary({Json? subject}) {
    final docs =
        (subject == null
            ? store.documents
            : store.subjectDocuments(subject['id']));
    final query = classroomQuery.trim().toLowerCase();
    final selected =
        docs
            .where(
              (d) =>
                  (classroomKind == 'All types' ||
                      d['kind'] == classroomKind) &&
                  (!classroomLocalOnly || d['availability'] != 'school') &&
                  (query.isEmpty ||
                      '${d['subject']} ${store.subject(d['subject'])['name']} ${d['title']} ${d['sections']}'
                          .toLowerCase()
                          .contains(query)),
            )
            .toList();
    final types = docs.map((d) => d['kind'] as String).toSet().toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pageHeading(
          'Your Classroom library',
          'Teacher notes, slides, worksheets, scopes and assessments, together in one place.',
        ),
        const SizedBox(height: 20),
        TextField(
          key: const ValueKey('classroom-search'),
          decoration: const InputDecoration(
            labelText: 'Search Classroom files',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged:
              (v) => setState(() {
                classroomQuery = v;
                classroomLimit = 24;
              }),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final type in ['All types', ...types])
              ChoiceChip(
                label: Text(type),
                selected: classroomKind == type,
                onSelected:
                    (_) => setState(() {
                      classroomKind = type;
                      classroomLimit = 24;
                    }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilterChip(
          label: const Text('Files available in For Rosa'),
          selected: classroomLocalOnly,
          onSelected:
              (v) => setState(() {
                classroomLocalOnly = v;
                classroomLimit = 24;
              }),
        ),
        const SizedBox(height: 10),
        Text(
          '${selected.length} documents · school links open with your school account',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 18),
        if (selected.isEmpty)
          const Text('No documents match. Try another search or type.'),
        for (final document in selected.take(classroomLimit))
          classroomRow(document),
        if (selected.length > classroomLimit)
          OutlinedButton(
            onPressed: () => setState(() => classroomLimit += 24),
            child: const Text('Show more files'),
          ),
      ],
    );
  }

  Widget classroomRow(Json d) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d['title'],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            '${store.subject(d['subject'])['name']} · ${d['kind']}${d['pages'] != null ? ' · ${d['pages']} pages' : ''}',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (d['availability'] != 'school')
                FilledButton.icon(
                  onPressed: () => openPaper(d),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                  label: const Text('Read PDF'),
                ),
              if (d['availability'] != 'school')
                OutlinedButton.icon(
                  onPressed: () => downloadOriginal(d),
                  icon: const Icon(Icons.download_outlined, size: 17),
                  label: Text('Download ${d['format']}'),
                ),
              if (d['availability'] == 'school')
                OutlinedButton.icon(
                  onPressed: () => openSchoolFile(d),
                  icon: const Icon(Icons.open_in_new, size: 17),
                  label: const Text('Open school document'),
                ),
            ],
          ),
          if (d['availability'] == 'school')
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'School sign-in required · this file has no offline copy in For Rosa. Access and downloads are managed by the school.',
                style: TextStyle(color: muted, fontSize: 11, height: 1.6),
              ),
            ),
          if (d['availability'] == 'school' &&
              ((d['sourceLinks'] as List?)?.length ?? 0) > 1)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('All ${d['sourceLinks'].length} posted copies'),
              children: [
                for (var i = 0; i < d['sourceLinks'].length; i++)
                  ListTile(
                    title: Text('Posted copy ${i + 1}'),
                    subtitle: Text(d['sourceLinks'][i]['label']),
                    trailing: const Icon(Icons.open_in_new, size: 17),
                    onTap:
                        () => openSchoolFile({
                          'sourceUrl': d['sourceLinks'][i]['url'],
                        }),
                  ),
              ],
            ),
          if (d['availability'] != 'school' && d['format'] != 'PDF')
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'PDF viewing copy · original document is available to download',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ),
        ],
      ),
    ),
  );

  Widget subjectFlashcards(String id) {
    final topics = store.subjectFlashcardTopics(id);
    return topics.isEmpty
        ? empty(
          'No flashcards available',
          'There are no flashcards for this subject.',
          Icons.style_outlined,
        )
        : topicList(topics, mode: 3);
  }

  Widget flashcardsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      pageHeading('Flashcards', 'Choose a subject and topic to review cards.'),
      const SizedBox(height: 25),
      for (final s in store.subjects) ...[
        Text(
          s['name'],
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: subjectColor(s),
          ),
        ),
        const SizedBox(height: 12),
        subjectFlashcards(s['id']),
        const SizedBox(height: 20),
      ],
    ],
  );
  Widget savedPage() {
    final ts =
        store.topics
            .where((t) => store.saved.contains('t:${t['id']}'))
            .toList();
    final ps =
        store.papers
            .where((p) => store.saved.contains('p:${p['id']}'))
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pageHeading(
          'Saved',
          'Your bookmarked topics and papers, ready when you need them.',
        ),
        const SizedBox(height: 24),
        if (ts.isEmpty && ps.isEmpty)
          empty(
            'No saved items',
            'Tap the bookmark on a topic or paper to keep it here.',
            Icons.bookmark_border_rounded,
          ),
        if (ts.isNotEmpty) ...[
          sectionTitle('Saved topics', ''),
          const SizedBox(height: 15),
          topicList(ts),
        ],
        if (ps.isNotEmpty) ...[
          const SizedBox(height: 22),
          sectionTitle('Saved resources', 'Original PDFs, one tap away'),
          const SizedBox(height: 15),
          for (final p in ps)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: paperRow(p),
            ),
        ],
      ],
    );
  }

  Widget empty(String title, String body, IconData icon) => panel(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 35),
      child: Column(
        children: [
          Icon(icon, color: purple, size: 42),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 9),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: muted, height: 1.7),
          ),
        ],
      ),
    ),
  );
  void chooseSubject(int tab) => showDialog<void>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Where shall we start?'),
          content: SizedBox(
            width: 390,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final s in store.subjects)
                  ListTile(
                    leading: Icon(subjectIcon(s['id']), color: subjectColor(s)),
                    title: Text(s['name']),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.pop(ctx);
                      openSubject(s['id'], tab: tab);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
  );
  void search() => showDialog<void>(
    context: context,
    builder:
        (ctx) => SearchLibrary(
          store: store,
          onTopic: (t) {
            Navigator.pop(ctx);
            openTopic(t);
          },
          onPaper: (p) {
            Navigator.pop(ctx);
            go('Past papers');
            openPaper(p);
          },
          onSubject: (s) {
            Navigator.pop(ctx);
            openSubject(s['id']);
          },
        ),
  );
  Future<void> install() async {
    final result = await platform.installApp();
    if (!mounted) return;
    if (result == 'accepted') {
      notice('For Rosa is being added to your device.');
      return;
    }
    if (result == 'dismissed') return;
    if (result == 'installed') {
      notice('You’re already using For Rosa as an installed app.');
      return;
    }
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Install For Rosa'),
            content: const SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Keep your study space on your home screen.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Android · Chrome',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Open the browser menu ⋮ and choose “Install app” or “Add to Home screen”.',
                    ),
                    SizedBox(height: 16),
                    Text(
                      'iPhone or iPad · Safari',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tap Share, then “Add to Home Screen”. If offered, turn on “Open as Web App”, then tap Add.',
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Computer · Chrome or Edge',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Use the install icon in the address bar, or the browser menu’s install option.',
                    ),
                    SizedBox(height: 18),
                    Text(
                      'If you opened this inside another app, open the same link in your browser first. Your progress stays on this device.',
                      style: TextStyle(color: muted, fontSize: 12, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  void showAbout() => showDialog<void>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Your For Rosa study library'),
          content: const SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Text(
                'Built from the supplied Grade 10 past papers and imported Classroom teaching material. Topics reflect the available sources and may not cover your entire curriculum.\n\nOriginal exam questions and supplied memos stay in their original PDFs. New practice, worked answers, revision notes and flashcards are generated learning material, not official marking guidelines. Some source memos contain errors; generated notes explain standard concepts.\n\nProgress and bookmarks are stored only in this browser or app on this device. They do not sync between devices, and clearing site data removes them. No account or learner details are collected. Download PDFs to keep your own copy; previously cached content can be available offline.\n\nFor Rosa is an independent study companion inspired by clear course dashboards and topic-based revision. It is not affiliated with Canvas or Save My Exams. Original exam materials belong to their respective owners.',
                style: TextStyle(fontSize: 13, height: 1.8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
  );
  String dateLabel() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final d = DateTime.now();
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: .7,
      ),
    ),
  );
}

class SearchLibrary extends StatefulWidget {
  const SearchLibrary({
    super.key,
    required this.store,
    required this.onTopic,
    required this.onPaper,
    required this.onSubject,
  });
  final StudyStore store;
  final ValueChanged<Json> onTopic, onPaper, onSubject;
  @override
  State<SearchLibrary> createState() => _SearchLibraryState();
}

class _SearchLibraryState extends State<SearchLibrary> {
  String query = '';
  bool matches(String value) => query
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .every((word) => value.toLowerCase().contains(word));
  @override
  Widget build(BuildContext context) {
    final topics =
        widget.store.topics
            .where(
              (t) => matches(
                '${t['title']} ${topicGroup(t)} ${(t['aliases'] as List?)?.join(' ') ?? ''} ${widget.store.subject(t['subject'])['name']}',
              ),
            )
            .toList();
    final papers =
        widget.store.papers
            .where(
              (p) =>
                  p['kind'] != 'unavailable' &&
                  matches(
                    '${p['title']} ${p['kind']} ${widget.store.subject(p['subject'])['name']}',
                  ),
            )
            .toList();
    final subjects =
        widget.store.subjects.where((s) => matches(s['name'])).toList();
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 660,
          maxHeight: math.min(650, MediaQuery.sizeOf(context).height - 50),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Search library',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close search',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextField(
                autofocus: true,
                onChanged: (v) => setState(() => query = v),
                decoration: const InputDecoration(
                  hintText: 'Try “physics 2024” or “mitosis”',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child:
                    query.trim().isEmpty
                        ? const Center(
                          child: Text(
                            'Search subjects, topics and past papers.',
                            style: TextStyle(color: muted),
                          ),
                        )
                        : ListView(
                          children: [
                            if (topics.isEmpty &&
                                papers.isEmpty &&
                                subjects.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(25),
                                child: Text(
                                  'No matches yet. Try a broader word.',
                                ),
                              ),
                            for (final s in subjects)
                              ListTile(
                                leading: Icon(
                                  subjectIcon(s['id']),
                                  color: subjectColor(s),
                                ),
                                title: Text(s['name']),
                                subtitle: const Text('Subject'),
                                onTap: () => widget.onSubject(s),
                              ),
                            for (final t in topics)
                              ListTile(
                                leading: const Icon(
                                  Icons.auto_stories_outlined,
                                  color: purple,
                                ),
                                title: Text(t['title']),
                                subtitle: Text(
                                  '${widget.store.subject(t['subject'])['name']} · Topic',
                                ),
                                onTap: () => widget.onTopic(t),
                              ),
                            for (final p in papers)
                              ListTile(
                                leading: const Icon(
                                  Icons.picture_as_pdf_outlined,
                                  color: purple,
                                ),
                                title: Text(p['title']),
                                subtitle: Text(
                                  '${widget.store.subject(p['subject'])['name']} · ${p['kind']}',
                                ),
                                onTap: () => widget.onPaper(p),
                              ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlashcardDeck extends StatefulWidget {
  const FlashcardDeck({
    super.key,
    required this.topic,
    required this.store,
    required this.color,
  });
  final Json topic;
  final StudyStore store;
  final Color color;
  @override
  State<FlashcardDeck> createState() => _FlashcardDeckState();
}

class _FlashcardDeckState extends State<FlashcardDeck> {
  int index = 0;
  bool flipped = false, reviewOnly = false, finished = false;
  List<Json> get cards => List<Json>.from(widget.topic['cards'] ?? []);
  List<int> get deck =>
      List.generate(cards.length, (i) => i)
          .where(
            (i) =>
                !reviewOnly ||
                !widget.store.known.contains('${widget.topic['id']}:$i'),
          )
          .toList();
  void next() {
    setState(() {
      flipped = false;
      if (index + 1 < deck.length) {
        index++;
      } else {
        finished = true;
      }
    });
  }

  void rate(bool known) {
    final card = deck[index.clamp(0, deck.length - 1)];
    widget.store.rateCard('${widget.topic['id']}:$card', known);
    setState(() {
      flipped = false;
      if (reviewOnly && known) {
        if (deck.isEmpty) {
          finished = true;
        } else {
          index = index.clamp(0, deck.length - 1);
        }
      } else if (index + 1 < deck.length) {
        index++;
      } else {
        finished = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentDeck = deck;
    final count = cards.length;
    if (count == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(Icons.style_outlined, color: muted, size: 36),
            SizedBox(height: 16),
            Text(
              'No flashcards available',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'There are no flashcards for this topic.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    final remembered =
        List.generate(count, (i) => i)
            .where(
              (i) => widget.store.known.contains('${widget.topic['id']}:$i'),
            )
            .length;
    if (finished || currentDeck.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(35),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.celebration_outlined, color: widget.color, size: 45),
            const SizedBox(height: 18),
            Text(
              currentDeck.isEmpty ? 'No cards to revisit' : 'Review complete',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '$remembered of $count cards marked as remembered.',
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed:
                      () => setState(() {
                        index = 0;
                        finished = false;
                        reviewOnly = false;
                        flipped = false;
                      }),
                  child: const Text('Study all cards'),
                ),
                if (remembered < count)
                  OutlinedButton(
                    onPressed:
                        () => setState(() {
                          index = 0;
                          finished = false;
                          reviewOnly = true;
                          flipped = false;
                        }),
                    child: const Text('Review cards to revisit'),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    index = index.clamp(0, currentDeck.length - 1);
    final card = cards[currentDeck[index]];
    return Column(
      children: [
        Row(
          children: [
            Text(
              'CARD ${index + 1} OF ${currentDeck.length}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: muted,
                letterSpacing: 1.3,
              ),
            ),
            const Spacer(),
            Text(
              '$remembered/$count remembered',
              style: TextStyle(fontSize: 11, color: widget.color),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Semantics(
          button: true,
          label:
              flipped
                  ? 'Flashcard answer. Tap to see question.'
                  : 'Flashcard question. Tap to reveal answer.',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(23),
              onTap: () => setState(() => flipped = !flipped),
              child: AnimatedContainer(
                duration:
                    MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 310),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: flipped ? widget.color : Colors.white,
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: widget.color.withValues(alpha: .25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: .06),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      flipped ? Icons.lightbulb_outline : Icons.style_outlined,
                      color: flipped ? Colors.white70 : widget.color,
                      size: 29,
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        flipped ? card['back'] : card['front'],
                        key: ValueKey('$index-$flipped'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: flipped ? 18 : 23,
                          height: 1.65,
                          fontWeight:
                              flipped ? FontWeight.w400 : FontWeight.w700,
                          color: flipped ? Colors.white : ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      flipped
                          ? 'Tap to see the question'
                          : 'Tap anywhere to reveal',
                      style: TextStyle(
                        fontSize: 11,
                        color: flipped ? Colors.white70 : muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (flipped)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => rate(false),
                icon: const Icon(Icons.replay_rounded, size: 17),
                label: const Text('Revisit this'),
              ),
              FilledButton.icon(
                onPressed: () => rate(true),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('I remembered it'),
              ),
            ],
          )
        else
          OutlinedButton(
            onPressed: () => setState(() => flipped = true),
            child: const Text('Reveal answer'),
          ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous card',
              onPressed:
                  index > 0
                      ? () => setState(() {
                        index--;
                        flipped = false;
                      })
                      : null,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            TextButton(
              onPressed: next,
              child: const Text(
                'Skip for now →',
                style: TextStyle(fontSize: 12),
              ),
            ),
            TextButton(
              onPressed:
                  () => setState(() {
                    index = 0;
                    reviewOnly = !reviewOnly;
                    flipped = false;
                  }),
              child: Text(
                reviewOnly ? 'Show all' : 'Only cards to revisit',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const Text(
          'Generated study cards · your ratings stay on this device',
          style: TextStyle(fontSize: 10, color: muted),
        ),
      ],
    );
  }
}
