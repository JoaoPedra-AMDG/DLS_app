import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Json = Map<String, dynamic>;

class StudyStore extends ChangeNotifier {
  StudyStore(this.data, this.prefs) {
    saved = prefs.getStringList('saved')?.toSet() ?? {};
    completed = prefs.getStringList('completed')?.toSet() ?? {};
    known = prefs.getStringList('known')?.toSet() ?? {};
    lastTopic = prefs.getString('lastTopic');
  }
  final Json data;
  final SharedPreferences prefs;
  late Set<String> saved, completed, known;
  String? lastTopic;
  String? persistenceError;
  List<Json> get subjects => List<Json>.from(data['subjects']);
  List<Json> get papers => List<Json>.from(data['papers']);
  List<Json> get topics => List<Json>.from(data['topics']);
  List<Json> get documents => List<Json>.from(data['classroom'] ?? []);
  List<Json> subjectDocuments(String id) =>
      documents
          .where(
            (d) =>
                List<String>.from(d['subjects'] ?? [d['subject']]).contains(id),
          )
          .toList();
  List<Json> topicDocuments(Json t) =>
      documents
          .where(
            (d) => List<String>.from(
              t['classroomSources'] ?? [],
            ).contains(d['id']),
          )
          .toList();
  Json subject(String id) => subjects.firstWhere((s) => s['id'] == id);
  Json paper(String id) => papers.firstWhere((p) => p['id'] == id);
  List<Json> subjectTopics(String id) =>
      topics.where((t) => t['subject'] == id).toList();
  List<Json> subjectFlashcardTopics(String id) =>
      subjectTopics(
        id,
      ).where((t) => (t['cards'] as List?)?.isNotEmpty ?? false).toList();
  List<Json> subjectPapers(String id) =>
      papers
          .where((p) => p['subject'] == id && p['kind'] != 'unavailable')
          .toList();
  Future<void> _persist(String key, Set<String> values) async {
    try {
      if (!await prefs.setStringList(key, values.toList())) {
        persistenceError =
            'This browser could not save your progress. Keep this tab open.';
      }
    } catch (_) {
      persistenceError =
          'Progress is available in this session, but device storage is unavailable.';
    }
    notifyListeners();
  }

  void toggleSaved(String id) {
    saved.contains(id) ? saved.remove(id) : saved.add(id);
    notifyListeners();
    _persist('saved', saved);
  }

  void toggleComplete(String id) {
    completed.contains(id) ? completed.remove(id) : completed.add(id);
    notifyListeners();
    _persist('completed', completed);
  }

  void rateCard(String id, bool remember) {
    remember ? known.add(id) : known.remove(id);
    notifyListeners();
    _persist('known', known);
  }

  Future<void> rememberTopic(String id) async {
    lastTopic = id;
    try {
      await prefs.setString('lastTopic', id);
    } catch (_) {
      /* Session still works. */
    }
  }

  static Future<StudyStore> load() async {
    final data =
        jsonDecode(await rootBundle.loadString('assets/content.json')) as Json;
    return StudyStore(data, await SharedPreferences.getInstance());
  }
}

const ink = Color(0xFF25233D);
const muted = Color(0xFF737185);
const purple = Color(0xFF6654D9);
const canvas = Color(0xFFF8F8FC);
String topicGroup(Json topic) =>
    (topic['group'] ?? topic['division'] ?? 'Topics') as String;
Color subjectColor(Json s) => Color(int.parse('FF${s['color']}', radix: 16));
Color subjectLight(Json s) => Color(int.parse('FF${s['light']}', radix: 16));
IconData subjectIcon(String id) => switch (id) {
  'maths' => Icons.calculate_outlined,
  'ap' => Icons.functions_rounded,
  'physical' => Icons.science_outlined,
  'life' => Icons.eco_outlined,
  'english' => Icons.menu_book_outlined,
  're' => Icons.church_outlined,
  _ => Icons.sports_basketball_outlined,
};
