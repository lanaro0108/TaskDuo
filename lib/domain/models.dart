enum TaskCategory {
  kitchen('Cozinha', 'bubble'),
  bedroom('Quarto', 'bed'),
  bathroom('Banheiro', 'toilet'),
  living('Sala', 'sofa'),
  general('Geral', 'bin');

  const TaskCategory(this.label, this.art);
  final String label;
  final String art;
}

enum Difficulty {
  easy('Leve', 15, 5),
  medium('Média', 25, 10),
  hard('Caprichada', 40, 15);

  const Difficulty(this.label, this.xp, this.coins);
  final String label;
  final int xp;
  final int coins;
}

enum Recurrence {
  none('Uma vez'),
  daily('Todos os dias'),
  weekly('Toda semana');

  const Recurrence(this.label);
  final String label;
}

DateTime dayOnly(DateTime v) => DateTime(v.year, v.month, v.day);
String dayKey(DateTime v) =>
    '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
DateTime weekStart(DateTime v) =>
    dayOnly(v).subtract(Duration(days: v.weekday - 1));
String shortDate(DateTime v) =>
    '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}';

class Member {
  Member({
    required this.id,
    required this.name,
    required this.avatar,
    this.baseXp = 0,
    this.baseCompleted = 0,
  });
  final String id;
  final String name;
  final int avatar;
  final int baseXp;
  final int baseCompleted;
  Member copyWith({String? name, int? avatar}) => Member(
    id: id,
    name: name ?? this.name,
    avatar: avatar ?? this.avatar,
    baseXp: baseXp,
    baseCompleted: baseCompleted,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'baseXp': baseXp,
    'baseCompleted': baseCompleted,
  };
  factory Member.fromJson(Map<String, dynamic> j) => Member(
    id: j['id'],
    name: j['name'],
    avatar: j['avatar'],
    baseXp: j['baseXp'],
    baseCompleted: j['baseCompleted'],
  );
}

class HouseTask {
  const HouseTask({
    required this.id,
    required this.title,
    required this.memberId,
    required this.category,
    required this.difficulty,
    required this.due,
    required this.xp,
    required this.coins,
    this.description = '',
    this.recurrence = Recurrence.none,
    this.completedAt,
  });
  final String id, title, description, memberId;
  final TaskCategory category;
  final Difficulty difficulty;
  final DateTime due;
  final int xp, coins;
  final Recurrence recurrence;
  final DateTime? completedAt;
  bool get done => completedAt != null;
  HouseTask complete(DateTime at) => HouseTask(
    id: id,
    title: title,
    description: description,
    memberId: memberId,
    category: category,
    difficulty: difficulty,
    due: due,
    xp: xp,
    coins: coins,
    recurrence: recurrence,
    completedAt: at,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'memberId': memberId,
    'category': category.name,
    'difficulty': difficulty.name,
    'due': due.toIso8601String(),
    'xp': xp,
    'coins': coins,
    'recurrence': recurrence.name,
    'completedAt': completedAt?.toIso8601String(),
  };
  factory HouseTask.fromJson(Map<String, dynamic> j) => HouseTask(
    id: j['id'],
    title: j['title'],
    description: j['description'],
    memberId: j['memberId'],
    category: TaskCategory.values.byName(j['category']),
    difficulty: Difficulty.values.byName(j['difficulty']),
    due: DateTime.parse(j['due']),
    xp: j['xp'],
    coins: j['coins'],
    recurrence: Recurrence.values.byName(j['recurrence']),
    completedAt: j['completedAt'] == null
        ? null
        : DateTime.parse(j['completedAt']),
  );
}

class Completion {
  const Completion({
    required this.taskId,
    required this.title,
    required this.memberId,
    required this.at,
    required this.xp,
    required this.coins,
    required this.category,
  });
  final String taskId, title, memberId;
  final DateTime at;
  final int xp, coins;
  final TaskCategory category;
  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'title': title,
    'memberId': memberId,
    'at': at.toIso8601String(),
    'xp': xp,
    'coins': coins,
    'category': category.name,
  };
  factory Completion.fromJson(Map<String, dynamic> j) => Completion(
    taskId: j['taskId'],
    title: j['title'],
    memberId: j['memberId'],
    at: DateTime.parse(j['at']),
    xp: j['xp'],
    coins: j['coins'],
    category: TaskCategory.values.byName(j['category']),
  );
}

class HouseReward {
  const HouseReward({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.art,
  });
  final String id, title, description, art;
  final int cost;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'cost': cost,
    'art': art,
  };
  factory HouseReward.fromJson(Map<String, dynamic> j) => HouseReward(
    id: j['id'],
    title: j['title'],
    description: j['description'],
    cost: j['cost'],
    art: j['art'],
  );
}

class Redemption {
  const Redemption({
    required this.id,
    required this.rewardId,
    required this.title,
    required this.art,
    required this.memberId,
    required this.cost,
    required this.at,
    this.used = false,
  });
  final String id, rewardId, title, art, memberId;
  final int cost;
  final DateTime at;
  final bool used;
  Redemption markUsed() => Redemption(
    id: id,
    rewardId: rewardId,
    title: title,
    art: art,
    memberId: memberId,
    cost: cost,
    at: at,
    used: true,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'rewardId': rewardId,
    'title': title,
    'art': art,
    'memberId': memberId,
    'cost': cost,
    'at': at.toIso8601String(),
    'used': used,
  };
  factory Redemption.fromJson(Map<String, dynamic> j) => Redemption(
    id: j['id'],
    rewardId: j['rewardId'],
    title: j['title'],
    art: j['art'],
    memberId: j['memberId'],
    cost: j['cost'],
    at: DateTime.parse(j['at']),
    used: j['used'],
  );
}

class HouseActivity {
  const HouseActivity({
    required this.text,
    required this.art,
    required this.at,
  });
  final String text, art;
  final DateTime at;
  Map<String, dynamic> toJson() => {
    'text': text,
    'art': art,
    'at': at.toIso8601String(),
  };
  factory HouseActivity.fromJson(Map<String, dynamic> j) => HouseActivity(
    text: j['text'],
    art: j['art'],
    at: DateTime.parse(j['at']),
  );
}

class Achievement {
  const Achievement(
    this.title,
    this.description,
    this.art,
    this.current,
    this.target,
  );
  final String title, description, art;
  final int current, target;
  bool get unlocked => current >= target;
  double get progress => (current / target).clamp(0, 1);
}
