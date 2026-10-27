import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/local_store.dart';
import 'models.dart';

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
  String _id() => '${clock().microsecondsSinceEpoch}-${_sequence++}';
  Member member(String id) => _members.firstWhere((m) => m.id == id);
  Future<void> load() async {
    try {
      final saved = await store.read();
      _readFailed = false;
      if (saved == null) {
        _seed();
        return;
      }
      final j = jsonDecode(saved) as Map<String, dynamic>;
      if (j['version'] != 1) {
        throw const FormatException('Unsupported storage version');
      }
      final members = (j['members'] as List)
          .map((e) => Member.fromJson(e))
          .toList();
      final tasks = (j['tasks'] as List)
          .map((e) => HouseTask.fromJson(e))
          .toList();
      final completions = (j['completions'] as List)
          .map((e) => Completion.fromJson(e))
          .toList();
      final rewards = (j['rewards'] as List)
          .map((e) => HouseReward.fromJson(e))
          .toList();
      final redemptions = (j['redemptions'] as List)
          .map((e) => Redemption.fromJson(e))
          .toList();
      if (members.length != 2 || !members.any((m) => m.id == j['activeId'])) {
        throw const FormatException('Invalid household');
      }
      _members = members;
      _tasks = tasks;
      _completions = completions;
      _rewards = rewards;
      _redemptions = redemptions;
      _activities = (j['activities'] as List)
          .map((e) => HouseActivity.fromJson(e))
          .toList();
      _weeklyBonuses = (j['weeklyBonuses'] as List).cast<String>().toSet();
      _activeId = j['activeId'];
      _themeMode = ThemeMode.values.byName(j['theme']);
      _notifications = j['notifications'];
      _animations = j['animations'];
      _sounds = j['sounds'];
      _sampleData = j['sampleData'];
      _sequence = j['sequence'] as int? ?? 0;
      persistenceError = null;
    } catch (_) {
      _seed();
      _readFailed = true;
      persistenceError = 'Não conseguimos ler os dados salvos. Seus dados anteriores não foram sobrescritos. Tente carregar novamente.';
    }
    notifyListeners();
  }

  Map<String, dynamic> _json() => {
    'version': 1,
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
    final i = _members.indexWhere((m) => m.id == id);
    _members[i] = _members[i].copyWith(name: name.trim(), avatar: avatar);
    _changed();
  }

  int xp(String id) =>
      member(id).baseXp +
      _completions.where((c) => c.memberId == id).fold(0, (a, c) => a + c.xp);
  int coins(String id) =>
      _completions
          .where((c) => c.memberId == id)
          .fold(0, (a, c) => a + c.coins) +
      _weeklyBonuses.length * 50 -
      _redemptions.where((r) => r.memberId == id).fold(0, (a, r) => a + r.cost);
  int level(String id) => xp(id) ~/ 500 + 1;
  int completedCount(String id) =>
      member(id).baseCompleted +
      _completions.where((c) => c.memberId == id).length;
  int streak(String id) {
    final dates = _completions
        .where((c) => c.memberId == id)
        .map((c) => dayKey(c.at))
        .toSet();
    var cursor = dates.contains(dayKey(today))
        ? today
        : today.subtract(const Duration(days: 1));
    var result = 0;
    while (dates.contains(dayKey(cursor))) {
      result++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return result;
  }

  List<Completion> inPeriod(int period, {String? id}) =>
      _completions.where((c) {
        if (id != null && c.memberId != id) return false;
        final start = period == 0
            ? weekStart(today)
            : DateTime(today.year, today.month);
        return period == 2 ||
            (!c.at.isBefore(start) &&
                c.at.isBefore(today.add(const Duration(days: 1))));
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
      coins: existing != null && existing.difficulty == difficulty
          ? existing.coins
          : difficulty.coins,
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
      coins: task.coins,
      category: task.category,
    );
    _tasks[i] = task.complete(at);
    _completions.add(completion);
    if (task.recurrence != Recurrence.none) {
      final base = task.due.isAfter(today) ? task.due : today;
      final next = base.add(
        Duration(days: task.recurrence == Recurrence.daily ? 1 : 7),
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
          coins: task.coins,
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
      _log('Desafio da semana concluído! +50 moedas para cada.', 'gift');
    }
    _changed();
    return completion;
  }

  String? redeem(String rewardId) {
    final reward = _rewards.where((r) => r.id == rewardId).firstOrNull;
    if (reward == null) return 'Esta recompensa não está mais disponível.';
    if (coins(active.id) < reward.cost) {
      return 'Faltam ${reward.cost - coins(active.id)} moedas para esta recompensa.';
    }
    _redemptions.add(
      Redemption(
        id: _id(),
        rewardId: reward.id,
        title: reward.title,
        art: reward.art,
        memberId: active.id,
        cost: reward.cost,
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

  void addReward(String title, String description, int cost, String art) {
    if (title.trim().isEmpty ||
        title.trim().length > 70 ||
        cost < 1 ||
        cost > 9999) {
      throw ArgumentError('Confira o nome e o custo da recompensa.');
    }
    _rewards.add(
      HouseReward(
        id: _id(),
        title: title.trim(),
        description: description.trim(),
        cost: cost,
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
        streak(id),
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
              dayKey(c.at) == dayKey(today.subtract(Duration(days: 6 - i))),
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
      Member(
        id: 'ana',
        name: 'Ana',
        avatar: 0,
        baseXp: 2000,
        baseCompleted: 33,
      ),
      Member(
        id: 'bruna',
        name: 'Bruna',
        avatar: 1,
        baseXp: 2000,
        baseCompleted: 28,
      ),
    ];
    _activeId = 'ana';
    _tasks = [];
    _completions = [];
    _redemptions = [];
    _weeklyBonuses = {};
    _activities = [];
    final values = [30, 25, 20, 40, 35, 30, 20, 25, 30, 15, 25, 25];
    for (var i = 0; i < values.length; i++) {
      _completions.add(
        Completion(
          taskId: 'example-ana-$i',
          title: 'Cuidar da casa',
          memberId: 'ana',
          at: today
              .subtract(Duration(days: i % 7))
              .add(const Duration(hours: 8)),
          xp: values[i],
          coins: 10,
          category: TaskCategory.values[i % 5],
        ),
      );
      if (i < 10) {
        _completions.add(
          Completion(
            taskId: 'example-bruna-$i',
            title: 'Cuidar da casa',
            memberId: 'bruna',
            at: today
                .subtract(Duration(days: i % 6))
                .add(const Duration(hours: 9)),
            xp: 28,
            coins: 10,
            category: TaskCategory.values[(i + 1) % 5],
          ),
        );
      }
    }
    final titles = [
      'Lavar a louça',
      'Organizar o quarto',
      'Limpar o banheiro',
      'Tirar o lixo',
      'Limpar a sala',
    ];
    final categories = [
      TaskCategory.kitchen,
      TaskCategory.bedroom,
      TaskCategory.bathroom,
      TaskCategory.general,
      TaskCategory.living,
    ];
    final points = [20, 15, 25, 10, 20];
    for (var i = 0; i < titles.length; i++) {
      _tasks.add(
        HouseTask(
          id: 'starter-$i',
          title: titles[i],
          description: [
            'Deixar a pia e a bancada limpinhas.',
            'Guardar as roupas e arrumar a cama.',
            'Limpar a pia, o vaso e o chão.',
            'Separar a reciclagem e levar o lixo.',
            'Guardar os objetos e limpar o chão.',
          ][i],
          memberId: i == 1 || i == 4 ? 'bruna' : 'ana',
          category: categories[i],
          difficulty: i == 2 ? Difficulty.medium : Difficulty.easy,
          due: today.add(Duration(days: i == 3 ? 1 : 0)),
          xp: points[i],
          coins: i == 2 ? 10 : 5,
          recurrence: i == 0 ? Recurrence.daily : Recurrence.none,
        ),
      );
    }
    _rewards = const [
      HouseReward(
        id: 'movie',
        title: 'Escolher o filme da noite',
        description: 'Uma noite de cinema do seu jeito!',
        cost: 50,
        art: 'popcorn',
      ),
      HouseReward(
        id: 'dessert',
        title: 'Pedir sobremesa',
        description: 'Seu doce favorito para adoçar o dia.',
        cost: 100,
        art: 'icecream',
      ),
      HouseReward(
        id: 'break',
        title: 'Folga de uma tarefa leve',
        description: 'Combine com sua dupla e aproveite a pausa.',
        cost: 80,
        art: 'sleep',
      ),
      HouseReward(
        id: 'music',
        title: 'Escolher a música da limpeza',
        description: 'Hoje você comanda a playlist!',
        cost: 30,
        art: 'music',
      ),
      HouseReward(
        id: 'rest',
        title: 'Tempo extra de descanso',
        description: 'Um tempinho no sofá. Você merece.',
        cost: 150,
        art: 'sofa',
      ),
    ];
    _log('Sua dupla está pronta. Vamos cuidar da casa juntos?', 'gift');
  }

  int get todayDone =>
      _tasks.where((t) => t.done && dayOnly(t.completedAt!) == today).length;
  int get todayTotal => todayTasks.length + todayDone;
  double get dailyProgress =>
      todayTotal == 0 ? 0 : (todayDone / math.max(1, todayTotal));
}
