import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskduo/domain/duo_state.dart';
import 'package:taskduo/domain/models.dart';

import 'test_store.dart';

void main() {
  late DuoState state;
  late TestStore store;
  var now = DateTime(2026, 10, 26, 12);
  setUp(() async {
    now = DateTime(2026, 10, 26, 12);
    store = TestStore();
    state = DuoState(store, clock: () => now);
    await state.load();
  });
  void create(
    String title, {
    String member = 'ana',
    Recurrence recurrence = Recurrence.none,
  }) => state.saveTask(
    title: title,
    description: 'Cuidar da casa',
    memberId: member,
    category: TaskCategory.kitchen,
    difficulty: Difficulty.easy,
    due: now,
    recurrence: recurrence,
  );

  test('completion awards the assignee once and creates exactly one next recurrence', () {
    final original = state.tasks.firstWhere((t) => t.id == 'starter-0');
    final beforeXp = state.xp('ana'),
        beforeCoins = state.coins('ana'),
        beforeCount = state.completions.length;
    expect(state.completeTask('starter-0'), isNotNull);
    expect(state.completeTask('starter-0'), isNull);
    expect(state.xp('ana'), beforeXp + 20);
    expect(state.coins('ana'), beforeCoins + 5);
    expect(state.completions.length, beforeCount + 1);
    final next = state.tasks
        .where((t) => t.title == 'Lavar a louça' && !t.done)
        .toList();
    expect(next, hasLength(1));
    expect(next.single.due, DateTime(2026, 10, 27));
    expect(
      () => state.saveTask(
        existing: original,
        title: original.title,
        description: '',
        memberId: original.memberId,
        category: original.category,
        difficulty: original.difficulty,
        due: now,
        recurrence: original.recurrence,
      ),
      throwsStateError,
    );
    expect(state.completeTask(next.single.id), isNull);
    expect(state.xp('ana'), beforeXp + 20);
  });
  test('insufficient funds cannot create a redemption or negative balance', () {
    expect(state.redeem('movie'), isNull);
    expect(state.redeem('movie'), isNull);
    expect(state.coins('ana'), 20);
    expect(state.redeem('movie'), contains('Faltam 30'));
    expect(state.redemptions, hasLength(2));
    expect(state.coins('ana'), 20);
  });
  test(
    'profiles have separate balances and only own redemptions can be used',
    () {
      state.redeem('movie');
      final redeemed = state.redemptions.single;
      state.switchMember('bruna');
      state.useRedemption(redeemed.id);
      expect(state.redemptions.single.used, isFalse);
      expect(state.coins('bruna'), 100);
      state.redeem('break');
      expect(state.coins('bruna'), 20);
      expect(state.coins('ana'), 70);
      state.switchMember('ana');
      state.useRedemption(redeemed.id);
      expect(state.redemptions.first.used, isTrue);
    },
  );
  test(
    'latest state survives queued saves and a complete app reload',
    () async {
      state.completeTask('starter-2');
      state.setTheme(ThemeMode.dark);
      state.editMember('ana', 'Lia', 2);
      state.redeem('movie');
      state.setSounds(true);
      await state.flush();
      final restored = DuoState(store, clock: () => now);
      await restored.load();
      expect(restored.active.name, 'Lia');
      expect(restored.active.avatar, 2);
      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.sounds, isTrue);
      expect(
        restored.tasks.firstWhere((t) => t.id == 'starter-2').done,
        isTrue,
      );
      expect(restored.redemptions.single.title, 'Escolher o filme da noite');
      expect(restored.coins('ana'), state.coins('ana'));
      expect(restored.completions.length, state.completions.length);
    },
  );
  test(
    'weekly challenge pays each member once, even after more completions',
    () {
      state.startFresh();
      for (var i = 0; i < 10; i++) {
        create('Missão $i', member: i.isEven ? 'ana' : 'bruna');
        state.completeTask(state.tasks.last.id);
      }
      expect(state.challengeClaimed, isTrue);
      expect(state.coins('ana'), 75);
      expect(state.coins('bruna'), 75);
      create('Missão extra');
      state.completeTask(state.tasks.last.id);
      expect(state.coins('ana'), 80);
      expect(state.coins('bruna'), 75);
    },
  );
  test(
    'streak breaks after a missed day and ranking respects month boundaries',
    () {
      state.startFresh();
      now = DateTime(2026, 9, 30, 12);
      create('Missão setembro');
      state.completeTask(state.tasks.last.id);
      now = DateTime(2026, 10, 1, 12);
      create('Missão outubro');
      state.completeTask(state.tasks.last.id);
      expect(state.streak('ana'), 2);
      expect(state.periodXp('ana', 1), 15);
      expect(state.periodXp('ana', 2), 30);
      now = DateTime(2026, 10, 3, 12);
      expect(state.streak('ana'), 0);
    },
  );
  test('editing reassignment changes who earns points; deletion preserves earned history', () {
    final task = state.tasks.firstWhere((t) => t.id == 'starter-1');
    final before = state.xp('ana');
    state.saveTask(
      existing: task,
      title: 'Arrumar o quarto',
      description: '',
      memberId: 'ana',
      category: task.category,
      difficulty: task.difficulty,
      due: now,
      recurrence: Recurrence.none,
    );
    state.completeTask(task.id);
    state.deleteTask(task.id);
    expect(state.tasks.where((t) => t.id == task.id), isEmpty);
    expect(state.xp('ana'), before + task.xp);
    expect(state.completions.where((c) => c.taskId == task.id), hasLength(1));
  });
  test(
    'invalid task and reward input is rejected before changing the household',
    () {
      final count = state.tasks.length;
      expect(() => create('   '), throwsArgumentError);
      expect(state.tasks.length, count);
      expect(
        () => state.addReward('Prêmio', '', -5, 'gift'),
        throwsArgumentError,
      );
      expect(state.rewards, hasLength(5));
    },
  );
  test(
    'failed device writes are visible and retry saves the current state',
    () async {
      store.failWrites = true;
      state.setTheme(ThemeMode.dark);
      await state.flush();
      expect(state.persistenceError, isNotNull);
      expect(store.value, isNull);
      store.failWrites = false;
      state.retrySave();
      await state.flush();
      expect(state.persistenceError, isNull);
      final restored = DuoState(store);
      await restored.load();
      expect(restored.themeMode, ThemeMode.dark);
    },
  );
  test(
    'corrupt storage is diagnosed without overwriting the original bytes',
    () async {
      store.value = '{not valid JSON';
      final restored = DuoState(store);
      await restored.load();
      expect(restored.persistenceError, contains('ler os dados'));
      expect(store.value, '{not valid JSON');
      expect(store.writes, 0);
      restored.setTheme(ThemeMode.dark);
      await restored.flush();
      expect(store.value, '{not valid JSON');
      expect(restored.persistenceError, isNotNull);
    },
  );
}
