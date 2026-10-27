import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/local_store.dart';
import 'models.dart';
import 'household_snapshot.dart';

class DuoState extends ChangeNotifier {
  DuoState(this.store, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final LocalStore store;
  final DateTime Function() clock;
  List<Member> _members = [];
  List<HouseTask> _tasks = [];
  List<Completion> _completions = [];
  List<HouseReward> _rewards = [];
  List<Redemption> _redemptions = [];
  List<HouseActivity> _activities = [];
  Set<String> _weeklyBonuses = {};
  String _activeId = 'ana';
  ThemeMode _themeMode = ThemeMode.system;
  bool _notifications = true,
      _animations = true,
      _sounds = false,
      _sampleData = true;
  String? persistenceError;
  Future<void> _writes = Future.value();
  int _sequence = 0;
  bool _readFailed = false;
  DateTime? _lastObservedDay;
  late DateTime _competitionStart;
  List<Member> get members => List.unmodifiable(_members);
  List<HouseTask> get tasks => List.unmodifiable(_tasks);
  List<Completion> get completions => List.unmodifiable(_completions);
  List<HouseReward> get rewards => List.unmodifiable(_rewards);
  List<Redemption> get redemptions => List.unmodifiable(_redemptions);
  List<HouseActivity> get activities => List.unmodifiable(_activities.reversed);
  Member get active => _members.firstWhere((m) => m.id == _activeId);
  Member get partner => _members.firstWhere((m) => m.id != _activeId);
  ThemeMode get themeMode => _themeMode;
  bool get notifications => _notifications;
  bool get animations => _animations;
  bool get sounds => _sounds;
  bool get sampleData => _sampleData;
  DateTime get today => dayOnly(clock());
  DateTime get competitionStart => _competitionStart;
  String _id() => '${clock().microsecondsSinceEpoch}-${_sequence++}';
  Member member(String id) => _members.firstWhere((m) => m.id == id);
  void refreshDate() {
    if (_lastObservedDay == today) return;
    _lastObservedDay = today;
    notifyListeners();
  }

  Future<void> load() async {
    try {
      final saved = await store.read();
      if (saved == null) {
        _seed();
      } else {
        final json = jsonDecode(saved) as Map<String, dynamic>;
        final snapshot = HouseholdSnapshot(json);
        _members = snapshot.members;
        _tasks = snapshot.tasks;
        _completions = snapshot.completions;
        _rewards = snapshot.rewards;
        _redemptions = snapshot.redemptions;
        _activities = snapshot.activities;
        _weeklyBonuses = snapshot.weeklyBonuses.toSet();
        _activeId = snapshot.activeId;
        _themeMode = snapshot.theme;
        _notifications = snapshot.notifications;
        _animations = snapshot.animations;
        _sounds = snapshot.sounds;
        _sampleData = snapshot.sampleData;
        _sequence = snapshot.sequence;
        _competitionStart = json['version'] == 2
            ? DateTime.parse(json['competitionStart'] as String)
            : weekStart(today);
        if (json['version'] == 1) {
          _tasks.removeWhere((t) => t.id.startsWith('starter-'));
          _rewards.removeWhere(
            (r) => const {
              'movie',
              'dessert',
              'break',
              'music',
              'rest',
            }.contains(r.id),
          );
        }
        if (json['version'] == 1 && _sampleData) {
          _members = _members
              .map((m) => Member(id: m.id, name: m.name, avatar: m.avatar))
              .toList();
          _completions.removeWhere(
            (c) =>
                c.taskId.startsWith('example-ana-') ||
                c.taskId.startsWith('example-bruna-'),
          );
          _sampleData = false;
        }
      }
      _readFailed = false;
      _lastObservedDay = today;
      persistenceError = null;
    } catch (_) {
      if (_members.isEmpty) _seed();
      _readFailed = true;
      persistenceError = 'Não conseguimos ler os dados salvos. Seus dados anteriores não foram sobrescritos. Tente carregar novamente.';
    }
    notifyListeners();
  }

  Map<String, dynamic> _json() => {
    'version': 2,
    'competitionStart': dayKey(_competitionStart),
    'sequence': _sequence,
    'members': _members.map((e) => e.toJson()).toList(),
    'tasks': _tasks.map((e) => e.toJson()).toList(),
    'completions': _completions.map((e) => e.toJson()).toList(),
    'rewards': _rewards.map((e) => e.toJson()).toList(),
    'redemptions': _redemptions.map((e) => e.toJson()).toList(),
    'activities': _activities.map((e) => e.toJson()).toList(),
    'weeklyBonuses': _weeklyBonuses.toList(),
    'activeId': _activeId,
    'theme': _themeMode.name,
    'notifications': _notifications,
    'animations': _animations,
    'sounds': _sounds,
    'sampleData': _sampleData,
  };
  void _changed() {
    _lastObservedDay = today;
    notifyListeners();
    // A failed read must never silently replace a potentially recoverable save.
    if (_readFailed) return;
    final snapshot = jsonEncode(_json());
    _writes = _writes
        .then((_) => store.write(snapshot))
        .then((_) {
          if (persistenceError != null) {
            persistenceError = null;
            notifyListeners();
          }
        })
        .catchError((Object _) {
          persistenceError =
              'As alterações ainda não foram salvas. Tente salvar novamente.';
          notifyListeners();
        });
  }

  Future<void> flush() => _writes;
  void retrySave() => _changed();
  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    _changed();
  }

  void setNotifications(bool value) {
    _notifications = value;
    _changed();
  }

  void setAnimations(bool value) {
    _animations = value;
    _changed();
  }

  void setSounds(bool value) {
    _sounds = value;
    _changed();
  }

  void switchMember(String id) {
    member(id);
    _activeId = id;
    _changed();
  }

  void editMember(String id, String name, int avatar) {
    if (name.trim().isEmpty || name.trim().length > 24) {
      throw ArgumentError('Use um nome de 1 a 24 caracteres.');
    }
    if (avatar < 0 || avatar >= avatarOptions.length) {
      throw ArgumentError('Escolha um dos avatares disponíveis.');
    }
    member(id);
    final i = _members.indexWhere((m) => m.id == id);
    _members[i] = _members[i].copyWith(name: name.trim(), avatar: avatar);
    _changed();
  }

  int xp(String id) =>
      member(id).baseXp +
      _completions.where((c) => c.memberId == id).fold(0, (a, c) => a + c.xp);
  int points(String id) => periodXp(id, 0);

  List<CompetitionResult> get closedCompetitions {
    final periods = <String, DateTime>{};
    final current = weekStart(today);
    for (final c in _completions) {
      final start = weekStart(c.at.toLocal());
      if (!start.isBefore(_competitionStart) && start.isBefore(current)) {
        periods[dayKey(start)] = start;
      }
    }
    return periods.values
        .map(
          (start) => CompetitionResult(
            start: start,
            scores: {
              for (final m in _members)
                m.id: _completions
                    .where(
                      (c) =>
                          c.memberId == m.id &&
                          !c.at.isBefore(start) &&
                          c.at.isBefore(addCalendarDays(start, 7)),
                    )
                    .fold(0, (sum, c) => sum + c.xp),
            },
          ),
        )
        .toList()
      ..sort((a, b) => b.start.compareTo(a.start));
  }

  List<CompetitionResult> get unclaimedWins => closedCompetitions
      .where(
        (period) =>
            period.winnerId == active.id &&
            !_redemptions.any((r) => r.periodKey == period.key),
      )
      .toList();
  int level(String id) => xp(id) ~/ 500 + 1;
  int completedCount(String id) =>
      member(id).baseCompleted +
      _completions.where((c) => c.memberId == id).length;
  StreakSummary streakSummary(String id) {
    final currentDay = calendarDayNumber(today);
    final dates =
        _completions
            .where((c) => c.memberId == id)
            .map((c) => calendarDayNumber(c.at.toLocal()))
            .where((day) => day <= currentDay)
            .toSet()
            .toList()
          ..sort();
    var run = 0, longest = 0;
    int? previous;
    for (final day in dates) {
      run = previous != null && day == previous + 1 ? run + 1 : 1;
      longest = math.max(longest, run);
      previous = day;
    }
    return StreakSummary(
      current: previous != null && currentDay - previous <= 1 ? run : 0,
      longest: longest,
      completedToday: previous == currentDay,
    );
  }

  int streak(String id) => streakSummary(id).current;
  int longestStreak(String id) => streakSummary(id).longest;

  List<Completion> inPeriod(int period, {String? id}) =>
      _completions.where((c) {
        if (id != null && c.memberId != id) return false;
        final start = period == 0
            ? weekStart(today)
            : DateTime(today.year, today.month);
        return period == 2 ||
            (!c.at.isBefore(start) && c.at.isBefore(addCalendarDays(today, 1)));
      }).toList();
  int periodXp(String id, int period) =>
      (period == 2 ? member(id).baseXp : 0) +
      inPeriod(period, id: id).fold(0, (sum, c) => sum + c.xp);
  int get weeklyCount => inPeriod(0).length;
  bool get challengeClaimed =>
      _weeklyBonuses.contains(dayKey(weekStart(today)));
  List<HouseTask> get todayTasks =>
      _tasks.where((t) => !t.done && !dayOnly(t.due).isAfter(today)).toList()
        ..sort((a, b) => a.due.compareTo(b.due));
  void saveTask({
    HouseTask? existing,
    required String title,
    required String description,
    required String memberId,
    required TaskCategory category,
    required Difficulty difficulty,
    required DateTime due,
    required Recurrence recurrence,
  }) {
    if (title.trim().isEmpty || title.trim().length > 70) {
      throw ArgumentError('Use um título de 1 a 70 caracteres.');
    }
    if (description.trim().length > 240) {
      throw ArgumentError('Use uma descrição de até 240 caracteres.');
    }
    member(memberId);
    if (existing?.done ?? false) {
      throw StateError('Uma tarefa concluída faz parte do histórico.');
    }
    final task = HouseTask(
      id: existing?.id ?? _id(),
      title: title.trim(),
      description: description.trim(),
      memberId: memberId,
      category: category,
      difficulty: difficulty,
      due: dayOnly(due),
      recurrence: recurrence,
      xp: existing != null && existing.difficulty == difficulty
          ? existing.xp
          : difficulty.xp,
      coins: 0,
    );
    if (existing == null) {
      _tasks.add(task);
      _log('Nova tarefa: ${task.title}', category.art);
    } else {
      final i = _tasks.indexWhere((t) => t.id == existing.id);
      if (i < 0) throw StateError('Tarefa não encontrada.');
      if (_tasks[i].done) {
        throw StateError('Uma tarefa concluída faz parte do histórico.');
      }
      _tasks[i] = task;
    }
    _changed();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _changed();
  }

  Completion? completeTask(String id) {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i < 0 || _tasks[i].done) return null;
    final task = _tasks[i];
    // Prevent repeatedly claiming XP for future recurring occurrences.
    if (task.recurrence != Recurrence.none &&
        dayOnly(task.due).isAfter(today)) {
      return null;
    }
    final at = clock();
    final completion = Completion(
      taskId: id,
      title: task.title,
      memberId: task.memberId,
      at: at,
      xp: task.xp,
      coins: 0,
      category: task.category,
    );
    _tasks[i] = task.complete(at);
    _completions.add(completion);
    if (task.recurrence != Recurrence.none) {
      final base = task.due.isAfter(today) ? task.due : today;
      final next = addCalendarDays(
        base,
        task.recurrence == Recurrence.daily ? 1 : 7,
      );
      _tasks.add(
        HouseTask(
          id: _id(),
          title: task.title,
          description: task.description,
          memberId: task.memberId,
          category: task.category,
          difficulty: task.difficulty,
          due: dayOnly(next),
          xp: task.xp,
          coins: 0,
          recurrence: task.recurrence,
        ),
      );
    }
    _log(
      '${member(task.memberId).name} concluiu ${task.title.toLowerCase()}',
      task.category.art,
    );
    if (weeklyCount >= 10 && !challengeClaimed) {
      _weeklyBonuses.add(dayKey(weekStart(today)));
      _log(
        'Desafio da semana concluído! A dupla cuidou de dez tarefas.',
        'star',
      );
    }
    _changed();
    return completion;
  }

  String? redeem(String rewardId, {String? periodKey}) {
    final reward = _rewards.where((r) => r.id == rewardId).firstOrNull;
    if (reward == null) return 'Esta recompensa não está mais disponível.';
    final period = periodKey == null
        ? unclaimedWins.firstOrNull
        : closedCompetitions.where((p) => p.key == periodKey).firstOrNull;
    if (period == null) {
      return 'Aguarde o encerramento de uma semana em que você venceu.';
    }
    if (period.winnerId == null) {
      return 'A semana terminou empatada, sem recompensa.';
    }
    if (period.winnerId != active.id) {
      return 'Somente o vencedor desta semana pode escolher uma recompensa.';
    }
    if (_redemptions.any((r) => r.periodKey == period.key)) {
      return 'A recompensa desta semana já foi escolhida.';
    }
    _redemptions.add(
      Redemption(
        id: _id(),
        rewardId: reward.id,
        title: reward.title,
        art: reward.art,
        memberId: active.id,
        cost: 0,
        periodKey: period.key,
        at: clock(),
      ),
    );
    _log('${active.name} resgatou ${reward.title.toLowerCase()}', reward.art);
    _changed();
    return null;
  }

  void useRedemption(String id) {
    final i = _redemptions.indexWhere(
      (r) => r.id == id && r.memberId == active.id,
    );
    if (i < 0 || _redemptions[i].used) return;
    _redemptions[i] = _redemptions[i].markUsed();
    _changed();
  }

  void addReward(String title, String description, String art) {
    if (title.trim().isEmpty ||
        title.trim().length > 70 ||
        description.trim().length > 160 ||
        !supportedArtNames.contains(art)) {
      throw ArgumentError('Confira o nome e a descrição da recompensa.');
    }
    _rewards.add(
      HouseReward(
        id: _id(),
        title: title.trim(),
        description: description.trim(),
        art: art,
      ),
    );
    _changed();
  }

  List<Achievement> achievements(String id) {
    final own = _completions.where((c) => c.memberId == id).toList();
    return [
      Achievement(
        'Primeira missão',
        'Conclua sua primeira tarefa.',
        'star',
        completedCount(id),
        1,
      ),
      Achievement(
        '7 dias seguidos',
        'Complete tarefas por 7 dias seguidos.',
        'fire',
        longestStreak(id),
        7,
      ),
      Achievement(
        'Faxina master',
        'Conclua 10 tarefas de banheiro.',
        'trophy',
        own.where((c) => c.category == TaskCategory.bathroom).length,
        10,
      ),
      Achievement(
        'Dupla imbatível',
        'Complete um desafio semanal em dupla.',
        'gift',
        _weeklyBonuses.length,
        1,
      ),
      Achievement(
        'Casa em dia',
        'Conclua 50 tarefas.',
        'broom',
        completedCount(id),
        50,
      ),
      Achievement(
        'Chef da casa',
        'Conclua 10 tarefas de cozinha.',
        'bubble',
        own.where((c) => c.category == TaskCategory.kitchen).length,
        10,
      ),
      Achievement(
        'Hora do prêmio',
        'Resgate 3 recompensas.',
        'popcorn',
        _redemptions.where((r) => r.memberId == id).length,
        3,
      ),
      Achievement(
        'Nível acima',
        'Chegue ao nível 10.',
        'sparkles',
        level(id),
        10,
      ),
    ];
  }

  List<int> weeklyBars(String id) => List.generate(
    7,
    (i) => _completions
        .where(
          (c) =>
              c.memberId == id &&
              dayKey(c.at.toLocal()) == dayKey(addCalendarDays(today, i - 6)),
        )
        .fold(0, (sum, c) => sum + c.xp),
  );
  void startFresh() {
    _readFailed = false;
    _members = _members
        .map((m) => Member(id: m.id, name: m.name, avatar: m.avatar))
        .toList();
    _completions.clear();
    _redemptions.clear();
    _weeklyBonuses.clear();
    _activities.clear();
    _tasks.removeWhere((t) => t.done);
    _sampleData = false;
    _competitionStart = weekStart(today);
    _log('Um novo começo para a sua dupla!', 'sparkles');
    _changed();
  }

  void _log(String text, String art) {
    _activities.add(HouseActivity(text: text, art: art, at: clock()));
    if (_activities.length > 100) {
      _activities.removeRange(0, _activities.length - 100);
    }
  }

  void _seed() {
    _members = [
      Member(id: 'ana', name: 'Ana', avatar: 0),
      Member(id: 'bruna', name: 'Bruna', avatar: 1),
    ];
    _activeId = 'ana';
    _tasks = [];
    _completions = [];
    _redemptions = [];
    _weeklyBonuses = {};
    _activities = [];
    _rewards = [];
    _sampleData = false;
    _competitionStart = weekStart(today);
  }

  int get todayDone =>
      _completions.where((c) => dayOnly(c.at.toLocal()) == today).length;
  int get todayTotal => todayTasks.length + todayDone;
  double get dailyProgress =>
      todayTotal == 0 ? 0 : (todayDone / math.max(1, todayTotal));
}
