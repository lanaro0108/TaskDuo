import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskduo/domain/duo_state.dart';
import 'package:taskduo/domain/models.dart';

import 'test_store.dart';

void main() {
  late DuoState state;
  late TestStore store;
  late DateTime now;
  setUp(() async {
    now = DateTime(2026, 10, 26, 12);
    store = TestStore();
    state = DuoState(store, clock: () => now);
    await state.load();
  });
  String create(
    String title, {
    String member = 'ana',
    Recurrence recurrence = Recurrence.none,
  }) {
    state.saveTask(
      title: title,
      description: '',
      memberId: member,
      category: TaskCategory.kitchen,
      difficulty: Difficulty.easy,
      due: now,
      recurrence: recurrence,
    );
    return state.tasks.last.id;
  }

  void complete({String member = 'ana'}) =>
      state.completeTask(create('Cuidar da casa', member: member));

  test(
    'a new household is empty and can create and restore its first reward',
    () async {
      expect(state.tasks, isEmpty);
      expect(state.rewards, isEmpty);
      expect(state.completions, isEmpty);
      expect(state.xp('ana'), 0);
      state.addReward('Cinema', 'Escolher o filme', 'popcorn');
      await state.flush();
      final restored = DuoState(store, clock: () => now);
      await restored.load();
      expect(restored.persistenceError, isNull);
      expect(restored.rewards.single.title, 'Cinema');
      restored.addReward('Sobremesa', '', 'icecream');
      expect(restored.rewards, hasLength(2));
    },
  );

  test('completion awards the assignee once and blocks the next recurring occurrence', () {
    final id = create('Louça', member: 'bruna', recurrence: Recurrence.daily);
    final original = state.tasks.last;
    expect(state.completeTask(id), isNotNull);
    expect(state.completeTask(id), isNull);
    expect(state.points('bruna'), 15);
    expect(state.points('ana'), 0);
    expect(state.tasks.last.due, DateTime(2026, 10, 27));
    expect(state.completeTask(state.tasks.last.id), isNull);
    expect(
      () => state.saveTask(
        existing: original,
        title: 'Outra',
        description: '',
        memberId: 'ana',
        category: original.category,
        difficulty: original.difficulty,
        due: now,
        recurrence: Recurrence.none,
      ),
      throwsStateError,
    );
  });

  test(
    'only the winner can choose one reward after the week has closed',
    () async {
      state.addReward('Cinema', '', 'popcorn');
      final reward = state.rewards.single.id;
      complete();
      complete();
      complete(member: 'bruna');
      expect(state.redeem(reward), isNotNull);
      expect(state.redemptions, isEmpty);
      now = DateTime(2026, 11, 1, 23, 59, 59);
      expect(state.redeem(reward), isNotNull);
      now = DateTime(2026, 11, 2);
      expect(state.points('ana'), 0);
      expect(state.xp('ana'), 30);
      final result = state.closedCompetitions.single;
      expect(result.winnerId, 'ana');
      state.switchMember('bruna');
      expect(state.redeem(reward, periodKey: result.key), isNotNull);
      state.switchMember('ana');
      expect(state.redeem(reward, periodKey: result.key), isNull);
      expect(state.redeem(reward, periodKey: result.key), isNotNull);
      expect(state.redemptions, hasLength(1));
      expect(state.xp('ana'), 30);
      state.switchMember('bruna');
      state.useRedemption(state.redemptions.single.id);
      expect(state.redemptions.single.used, isFalse);
      state.switchMember('ana');
      state.useRedemption(state.redemptions.single.id);
      await state.flush();
      final restored = DuoState(store, clock: () => now);
      await restored.load();
      expect(restored.persistenceError, isNull);
      expect(restored.redemptions.single.used, isTrue);
      expect(restored.redeem(reward, periodKey: result.key), isNotNull);
    },
  );

  test('ties and empty weeks do not award a reward', () {
    state.addReward('Cinema', '', 'popcorn');
    complete();
    complete(member: 'bruna');
    now = DateTime(2026, 11, 2);
    final result = state.closedCompetitions.single;
    expect(result.winnerId, isNull);
    expect(
      state.redeem(state.rewards.single.id, periodKey: result.key),
      isNotNull,
    );
    now = DateTime(2026, 11, 9);
    expect(state.closedCompetitions, hasLength(1));
    expect(state.unclaimedWins, isEmpty);
  });

  test('unclaimed wins can be chosen later and are separate for each week', () {
    state.addReward('Cinema', '', 'popcorn');
    complete();
    now = DateTime(2026, 11, 2, 12);
    complete(member: 'bruna');
    now = DateTime(2026, 11, 9, 12);
    expect(state.unclaimedWins.single.key, '2026-10-26');
    expect(state.redeem(state.rewards.single.id), isNull);
    state.switchMember('bruna');
    expect(state.unclaimedWins.single.key, '2026-11-02');
    expect(state.redeem(state.rewards.single.id), isNull);
    expect(state.redemptions, hasLength(2));
  });

  test('streak counts distinct calendar days, preserves yesterday and the best run', () async {
    for (var i = 0; i < 7; i++) {
      now = DateTime(2026, 12, 27 + i, 12);
      complete();
      complete();
    }
    expect(state.streak('ana'), 7);
    expect(state.longestStreak('ana'), 7);
    expect(state.streak('bruna'), 0);
    now = DateTime(2027, 1, 3, 23, 59);
    expect(state.streak('ana'), 7);
    expect(state.streakSummary('ana').completedToday, isFalse);
    now = DateTime(2027, 1, 4);
    expect(state.streak('ana'), 0);
    expect(state.longestStreak('ana'), 7);
    expect(state.achievements('ana')[1].unlocked, isTrue);
    complete();
    expect(state.streak('ana'), 1);
    state.deleteTask(state.tasks.last.id);
    expect(state.todayDone, 1);
    expect(state.streak('ana'), 1);
    await state.flush();
    final restored = DuoState(store, clock: () => now);
    await restored.load();
    expect(restored.persistenceError, isNull);
    expect(restored.longestStreak('ana'), 7);
    expect(restored.achievements('ana')[1].unlocked, isTrue);
  });

  test('invalid commands leave the household unchanged', () {
    expect(() => create('   '), throwsArgumentError);
    expect(() => state.addReward('', '', 'gift'), throwsArgumentError);
    expect(
      () => state.addReward('Prêmio', '', '../other'),
      throwsArgumentError,
    );
    expect(
      () => state.editMember('ana', 'Lia', avatarOptions.length),
      throwsArgumentError,
    );
    expect(state.tasks, isEmpty);
    expect(state.rewards, isEmpty);
  });

  test('new avatar styles and all queued actions survive reload', () async {
    create('Plantas');
    state.setTheme(ThemeMode.dark);
    state.editMember('ana', 'Leo', 7);
    state.editMember('bruna', 'Lia', 4);
    state.setSounds(true);
    await state.flush();
    final restored = DuoState(store, clock: () => now);
    await restored.load();
    expect(restored.persistenceError, isNull);
    expect(restored.active.name, 'Leo');
    expect(restored.active.avatar, 7);
    expect(restored.partner.avatar, 4);
    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.sounds, isTrue);
    expect(restored.tasks.single.title, 'Plantas');
  });

  test(
    'failed writes can retry and corrupt reads never overwrite saved bytes',
    () async {
      store.failWrites = true;
      state.setTheme(ThemeMode.dark);
      await state.flush();
      expect(state.persistenceError, isNotNull);
      store.failWrites = false;
      state.retrySave();
      await state.flush();
      expect(state.persistenceError, isNull);
      store.value = '{invalid';
      final restored = DuoState(store, clock: () => now);
      await restored.load();
      restored.setTheme(ThemeMode.light);
      await restored.flush();
      expect(restored.persistenceError, isNotNull);
      expect(store.value, '{invalid');
    },
  );

  final invalidSaves = <String, void Function(Map<String, dynamic>)>{
    'duplicate members': (j) => j['members'][1]['id'] = 'ana',
    'orphan task': (j) => j['tasks'][0]['memberId'] = 'missing',
    'duplicate tasks': (j) => j['tasks'].add(j['tasks'][0]),
    'negative points': (j) => j['tasks'][0]['xp'] = -1,
    'unknown avatar': (j) => j['members'][0]['avatar'] = 99,
    'invalid reward': (j) => j['rewards'][0]['art'] = 'unknown',
    'inconsistent history': (j) =>
        j['tasks'][0]['completedAt'] = '2026-10-26T12:00:00.000',
    'invalid preferences': (j) => j['sounds'] = 'false',
    'unsupported version': (j) => j['version'] = 42,
    'invalid competition date': (j) => j['competitionStart'] = '2026-02-30',
  };
  for (final entry in invalidSaves.entries) {
    test('rejects ${entry.key} without overwriting the save', () async {
      create('Plantas');
      state.addReward('Cinema', '', 'popcorn');
      await state.flush();
      final json = jsonDecode(store.value!) as Map<String, dynamic>;
      entry.value(json);
      final original = jsonEncode(json);
      store.value = original;
      final restored = DuoState(store, clock: () => now);
      await restored.load();
      expect(restored.persistenceError, isNotNull);
      restored.setTheme(ThemeMode.dark);
      await restored.flush();
      expect(store.value, original);
    });
  }

  test('version 1 migration removes examples and preserves custom work and old redemptions', () async {
    final id = create('Minhas plantas');
    state.completeTask(id);
    state.addReward('Meu prêmio', '', 'gift');
    await state.flush();
    final j = jsonDecode(store.value!) as Map<String, dynamic>;
    j['version'] = 1;
    j.remove('competitionStart');
    j['sampleData'] = true;
    j['members'][0]['baseXp'] = 2000;
    j['members'][0]['baseCompleted'] = 33;
    j['rewards'][0]['cost'] = 50;
    j['rewards'].add(
      HouseReward(
        id: 'movie',
        title: 'Exemplo',
        description: '',
        cost: 50,
        art: 'popcorn',
      ).toJson(),
    );
    j['tasks'].add(
      HouseTask(
        id: 'starter-0',
        title: 'Exemplo',
        memberId: 'ana',
        category: TaskCategory.kitchen,
        difficulty: Difficulty.easy,
        due: now,
        xp: 20,
        coins: 5,
      ).toJson(),
    );
    j['completions'].add(
      Completion(
        taskId: 'example-ana-0',
        title: 'Exemplo',
        memberId: 'ana',
        at: now,
        xp: 30,
        coins: 100,
        category: TaskCategory.kitchen,
      ).toJson(),
    );
    j['redemptions'].add(
      Redemption(
        id: 'legacy-prize',
        rewardId: 'movie',
        title: 'Prêmio antigo',
        art: 'popcorn',
        memberId: 'ana',
        cost: 50,
        at: now,
      ).toJson(),
    );
    store.value = jsonEncode(j);
    final restored = DuoState(store, clock: () => now);
    await restored.load();
    expect(restored.persistenceError, isNull);
    expect(restored.tasks.single.title, 'Minhas plantas');
    expect(restored.rewards.single.title, 'Meu prêmio');
    expect(restored.completions, hasLength(1));
    expect(restored.xp('ana'), 15);
    expect(restored.redemptions.single.title, 'Prêmio antigo');
    expect(restored.unclaimedWins, isEmpty);
    restored.setTheme(ThemeMode.dark);
    await restored.flush();
    expect(jsonDecode(store.value!)['version'], 2);
    final again = DuoState(store, clock: () => now);
    await again.load();
    expect(again.persistenceError, isNull);
    expect(again.completions, hasLength(1));
  });

  test(
    'date refresh notifies once per day without saving a new transaction',
    () async {
      var notifications = 0;
      state.addListener(() => notifications++);
      state.refreshDate();
      expect(notifications, 0);
      now = DateTime(2026, 10, 27);
      state.refreshDate();
      state.refreshDate();
      expect(notifications, 1);
      expect(store.writes, 0);
    },
  );
  test('the collective challenge records once without adding extra points', () {
    for (var i = 0; i < 11; i++) {
      complete();
    }
    expect(state.challengeClaimed, isTrue);
    expect(state.points('ana'), 165);
    expect(
      state.activities.where((a) => a.text.startsWith('Desafio da semana')),
      hasLength(1),
    );
    expect(state.achievements('ana')[3].unlocked, isTrue);
  });
}
