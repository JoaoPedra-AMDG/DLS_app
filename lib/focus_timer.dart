import 'dart:async';
import 'package:flutter/material.dart';
import 'models.dart';

/// Owned by the study shell so changing screens does not discard a session.
class FocusSession extends ChangeNotifier {
  FocusSession({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  int minutes = 25, seconds = 25 * 60, completed = 0;
  bool isBreak = false;
  Timer? _timer;
  DateTime? _deadline;
  bool get running => _deadline != null;
  void _tick() {
    if (_deadline == null) return;
    seconds = (_deadline!.difference(_clock()).inMilliseconds / 1000)
        .ceil()
        .clamp(0, minutes * 60);
    if (seconds == 0) {
      if (!isBreak) completed++;
      _stop();
    }
    notifyListeners();
  }

  void _stop() {
    _timer?.cancel();
    _deadline = null;
  }

  void toggle() {
    if (running) {
      _tick();
      _stop();
    } else {
      if (seconds == 0) seconds = minutes * 60;
      _deadline = _clock().add(Duration(seconds: seconds));
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
    notifyListeners();
  }

  void select(int duration, {bool rest = false}) {
    _stop();
    minutes = duration;
    seconds = duration * 60;
    isBreak = rest;
    notifyListeners();
  }

  void reset() => select(minutes, rest: isBreak);
  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key, required this.session});
  final FocusSession session;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder:
        (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pomodoro',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Choose a focus session or break below.',
                  style: TextStyle(color: muted, height: 1.6),
                ),
                const SizedBox(height: 26),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final (label, length, rest) in [
                      ('Focus · 25 min', 25, false),
                      ('Short break · 5 min', 5, true),
                      ('Long break · 15 min', 15, true),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected:
                            session.minutes == length &&
                            session.isBreak == rest,
                        onSelected: (_) => session.select(length, rest: rest),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF292744),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        session.isBreak ? 'BREAK' : 'FOCUS SESSION',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFC9C1F5),
                          fontSize: 11,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value:
                                    1 -
                                    session.seconds / (session.minutes * 60),
                                strokeWidth: 9,
                                backgroundColor: Colors.white12,
                                color: const Color(0xFFC9C1F5),
                              ),
                            ),
                            Semantics(
                              liveRegion: session.seconds == 0,
                              child: Text(
                                '${(session.seconds ~/ 60).toString().padLeft(2, '0')}:${(session.seconds % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 51,
                                  fontWeight: FontWeight.w300,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        session.seconds == 0
                            ? (session.isBreak
                                ? 'Break complete. Ready for your next small step?'
                                : 'Focus session complete. Choose a break above.')
                            : session.isBreak
                            ? 'Stretch, look away from the screen, or get some water.'
                            : 'You can visit other study screens while this timer runs.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFDDD8ED),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 14,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: session.toggle,
                            icon: Icon(
                              session.running ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(
                              session.running
                                  ? 'Pause'
                                  : session.seconds == 0
                                  ? 'Start again'
                                  : 'Start / continue',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: session.reset,
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Reset'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${session.completed} focus sessions completed in this visit.',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep For Rosa open. Closing the app ends this timer. A sleeping device may delay the display; it catches up when active.',
                  style: TextStyle(color: muted, fontSize: 12, height: 1.6),
                ),
              ],
            ),
          ),
        ),
  );
}
