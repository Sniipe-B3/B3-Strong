import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/session_store.dart';
import '../../design_system/app_colors.dart';
import '../../domain/routine.dart';
import '../../domain/session.dart';

String formatDuration(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  if (seconds == 0 && milliseconds > 0) return '< 1 s';
  if (seconds < 60) return '$seconds s';
  final minutes = seconds ~/ 60;
  return '$minutes min ${(seconds % 60).toString().padLeft(2, '0')} s';
}

class SessionPage extends StatefulWidget {
  const SessionPage({
    super.key,
    required this.draft,
    required this.store,
    required this.onFinished,
  });

  final SessionDraft draft;
  final SessionStore store;
  final ValueChanged<SessionRecord> onFinished;

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> with WidgetsBindingObserver {
  Timer? _ticker;
  DateTime _lastTick = DateTime.now();
  Future<void> _pendingWrite = Future.value();
  bool _finishing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
    if (widget.draft.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startTicker() {
    _lastTick = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _tick();
      _ticker?.cancel();
      if (!widget.draft.paused && !widget.draft.isFinished) {
        setState(() => widget.draft.togglePause());
        _save();
      }
    } else if (state == AppLifecycleState.resumed) {
      _startTicker();
    }
  }

  void _tick() {
    final now = DateTime.now();
    // A throttled/hidden browser tab must not credit a long unseen exercise.
    final elapsed = math.min(
      1000,
      math.max(0, now.difference(_lastTick).inMilliseconds),
    );
    _lastTick = now;
    if (elapsed == 0 || widget.draft.isFinished) return;
    setState(() => widget.draft.advance(elapsed));
    _save();
    if (widget.draft.isFinished) _finish();
  }

  void _save() {
    final snapshot = SessionDraft.fromJsonString(
      widget.draft.toJsonString(),
      pauseOnRestore: false,
    );
    _pendingWrite = _pendingWrite
        .then((_) => widget.store.writeActive(snapshot))
        .catchError((Object _) {
          if (mounted) {
            setState(() => _error = 'Sauvegarde momentanément impossible.');
          }
        });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _ticker?.cancel();
    if (mounted) setState(() => _error = null);
    try {
      await _pendingWrite;
      final record = widget.draft.finish(DateTime.now());
      await widget.store.saveRecord(record);
      await widget.store.clearActive();
      if (mounted) widget.onFinished(record);
    } catch (_) {
      _finishing = false;
      if (mounted) {
        setState(() => _error = 'Enregistrement impossible. Réessayez.');
      }
    }
  }

  void _change(void Function() action) {
    _tick();
    if (widget.draft.isFinished) return;
    setState(action);
    _save();
    if (widget.draft.isFinished) _finish();
  }

  Future<void> _confirmStop() async {
    if (!widget.draft.paused) _change(widget.draft.togglePause);
    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arrêter la séance ?'),
        content: const Text(
          'Ce que vous avez fait sera conservé comme séance partielle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Rester en pause'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enregistrer et arrêter'),
          ),
        ],
      ),
    );
    if (mounted && shouldStop == true) _change(widget.draft.stop);
  }

  String get _easierInstruction =>
      switch (widget.draft.currentStep.exerciseId) {
        'plank' => 'Vous pouvez poser les genoux au sol.',
        'squat' => 'Vous pouvez réduire l’amplitude du mouvement.',
        _ => 'Vous pouvez ralentir et faire un côté à la fois.',
      };

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final exercise = draft.currentExercise;
    final textTheme = Theme.of(context).textTheme;
    final isTimed =
        draft.phase == SessionPhase.timed ||
        draft.phase == SessionPhase.preparation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre séance'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(onPressed: _confirmStop, child: const Text('Arrêter')),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              children: [
                Text(
                  'Étape ${draft.index + 1} sur ${draft.steps.length}',
                  style: const TextStyle(color: AppColors.accent),
                ),
                const SizedBox(height: 12),
                Text(exercise.name, style: textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'Objectif : ${exercise.targetLabel(draft.currentStep.target)}',
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          draft.paused
                              ? 'EN PAUSE'
                              : switch (draft.phase) {
                                  SessionPhase.preparation => 'PRÉPAREZ-VOUS',
                                  SessionPhase.timed => 'C’EST PARTI',
                                  SessionPhase.repetitions => 'À VOTRE RYTHME',
                                  SessionPhase.rest => 'REPOS',
                                  SessionPhase.finished => 'TERMINÉ',
                                },
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (draft.phase == SessionPhase.rest) ...[
                          Text(
                            '${draft.remainingRestSeconds}',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 78,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'secondes de repos avant la prochaine série',
                          ),
                        ] else if (isTimed) ...[
                          Text(
                            draft.phase == SessionPhase.preparation
                                ? '${draft.preparationSeconds}'
                                : '${draft.remainingSeconds}',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 78,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            draft.phase == SessionPhase.preparation
                                ? 'secondes avant de commencer'
                                : 'secondes restantes',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Temps actif : ${formatDuration(draft.currentActiveMilliseconds)}',
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                tooltip: 'Retirer une répétition',
                                onPressed: draft.paused
                                    ? null
                                    : () => _change(
                                        () => draft.changeRepetitions(-1),
                                      ),
                                icon: const Icon(Icons.remove),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 25,
                                ),
                                child: Text(
                                  '${draft.currentRepetitions}',
                                  style: const TextStyle(
                                    fontSize: 66,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: 'Ajouter une répétition',
                                onPressed: draft.paused
                                    ? null
                                    : () => _change(
                                        () => draft.changeRepetitions(1),
                                      ),
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                          const Text(
                            'Comptez uniquement les mouvements effectués.',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (draft.paused)
                  FilledButton.icon(
                    onPressed: () => _change(draft.togglePause),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Reprendre'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => _change(draft.togglePause),
                    icon: const Icon(Icons.pause_rounded),
                    label: const Text('Pause'),
                  ),
                if (draft.phase == SessionPhase.repetitions) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: draft.paused || draft.currentRepetitions == 0
                        ? null
                        : () => _change(draft.confirmRepetitions),
                    child: const Text('Valider les répétitions'),
                  ),
                ],
                const SizedBox(height: 10),
                if (draft.phase != SessionPhase.rest) ...[
                  OutlinedButton(
                    onPressed: draft.easierVariant
                        ? null
                        : () => _change(draft.useEasierVariant),
                    child: const Text('Variante plus facile'),
                  ),
                  if (draft.easierVariant) ...[
                    const SizedBox(height: 8),
                    Text(_easierInstruction, textAlign: TextAlign.center),
                  ],
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _change(draft.skip),
                  child: Text(
                    draft.phase == SessionPhase.rest
                        ? 'Passer le repos'
                        : 'Passer cet exercice',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  if (draft.isFinished)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Réessayer l’enregistrement'),
                    ),
                ],
                const SizedBox(height: 10),
                const Text(
                  'En cas de douleur inhabituelle, arrêtez le mouvement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SessionSummaryPage extends StatefulWidget {
  const SessionSummaryPage({
    super.key,
    required this.record,
    required this.onFeeling,
    required this.onClose,
  });

  final SessionRecord record;
  final Future<void> Function(String feeling) onFeeling;
  final VoidCallback onClose;

  @override
  State<SessionSummaryPage> createState() => _SessionSummaryPageState();
}

class _SessionSummaryPageState extends State<SessionSummaryPage> {
  bool saving = false;

  Future<void> chooseFeeling(String value) async {
    setState(() => saving = true);
    try {
      await widget.onFeeling(value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilan non sauvegardé. Réessayez.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilan de séance'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 68,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 16),
                Text(
                  record.outcome == SessionOutcome.completed
                      ? 'Séance terminée'
                      : 'Séance partielle enregistrée',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chaque petit pas compte.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Temps actif : ${formatDuration(record.activeMilliseconds)}',
                        ),
                        const SizedBox(height: 8),
                        Text('Répétitions : ${record.repetitions}'),
                        const SizedBox(height: 8),
                        Text(
                          'Durée totale : ${formatDuration(record.totalMilliseconds)}',
                        ),
                        const Divider(height: 28),
                        for (final step in record.steps)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${exerciseById(step.exerciseId).name} · ${switch (step.outcome) {
                                StepOutcome.completed => 'fait',
                                StepOutcome.partial => 'partiel',
                                StepOutcome.skipped => 'passé',
                              }} · '
                              '${step.repetitions > 0 ? '${step.repetitions} répétitions' : formatDuration(step.activeMilliseconds)}',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Comment vous sentez-vous ? (facultatif)'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final feeling in ['Facile', 'Bien', 'Difficile'])
                      ChoiceChip(
                        label: Text(feeling),
                        selected: record.feeling == feeling,
                        onSelected: saving
                            ? null
                            : (_) => chooseFeeling(feeling),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: saving ? null : widget.onClose,
                  child: const Text('Retour à aujourd’hui'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
