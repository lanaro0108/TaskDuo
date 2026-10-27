import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskduo/app.dart';
import 'package:taskduo/domain/duo_state.dart';
import 'package:taskduo/domain/models.dart';

import 'test_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
    await font.load();
  });
  DuoState? currentState;
  void appTest(String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await currentState?.flush();
        currentState?.dispose();
        currentState = null;
      }
    });
  }

  Future<DuoState> makeState({DateTime Function()? clock}) async {
    final state = DuoState(
      TestStore(),
      clock: clock ?? () => DateTime(2026, 10, 26, 12),
    );
    await state.load();
    return state;
  }

  void task(DuoState state, {DateTime? due}) => state.saveTask(
    title: 'Regar as plantas',
    description: '',
    memberId: 'ana',
    category: TaskCategory.general,
    difficulty: Difficulty.easy,
    due: due ?? state.today,
    recurrence: Recurrence.none,
  );
  Future<DuoState> start(
    WidgetTester tester, {
    DuoState? state,
    double width = 430,
    double height = 932,
    ThemeMode theme = ThemeMode.light,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loaded = state ?? await makeState();
    loaded.setAnimations(false);
    loaded.setTheme(theme);
    await loaded.flush();
    currentState = loaded;
    await tester.pumpWidget(TaskDuoApp(state: loaded));
    await tester.pumpAndSettle();
    return loaded;
  }

  appTest('create, search and complete a task from an empty household', (
    tester,
  ) async {
    final state = await start(tester);
    await tester.tap(find.text('Tarefas').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar tarefa'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Regar as plantas',
    );
    await tester.ensureVisible(find.text('Criar tarefa').last);
    await tester.tap(find.text('Criar tarefa').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'regar');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regar as plantas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir tarefa'));
    await tester.pumpAndSettle();
    expect(state.tasks.single.done, isTrue);
    expect(state.points('ana'), 15);
    expect(tester.takeException(), isNull);
  });

  appTest('create a first reward without a currency cost', (tester) async {
    final state = await start(tester);
    await tester.tap(find.text('Recompensas').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Criar recompensa da dupla'));
    await tester.tap(find.text('Criar recompensa da dupla'));
    await tester.pumpAndSettle();
    expect(find.text('Custo em moedas'), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, 'Cinema em casa');
    await tester.ensureVisible(find.text('Criar recompensa'));
    await tester.tap(find.text('Criar recompensa'));
    await tester.pumpAndSettle();
    expect(state.rewards.single.title, 'Cinema em casa');
    expect(tester.takeException(), isNull);
  });

  appTest('the winner chooses a single prize and marks it used', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 26, 12);
    final state = await makeState(clock: () => now);
    task(state);
    state.completeTask(state.tasks.single.id);
    state.addReward('Cinema em casa', '', 'popcorn');
    now = DateTime(2026, 11, 2, 12);
    await start(tester, state: state);
    await tester.tap(find.text('Recompensas').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cinema em casa'));
    await tester.tap(find.text('Cinema em casa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar meu prêmio'));
    await tester.pumpAndSettle();
    expect(state.redemptions, hasLength(1));
    await tester.tap(find.text('Meus prêmios'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Marcar como usada'));
    await tester.tap(find.text('Marcar como usada'));
    await tester.pumpAndSettle();
    expect(state.redemptions.single.used, isTrue);
    expect(tester.takeException(), isNull);
  });

  appTest(
    'all avatar combinations can be selected and a male curly portrait persists',
    (tester) async {
      final state = await start(tester, width: 320, height: 780);
      await tester.tap(find.text('Perfil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar meu perfil'));
      await tester.pumpAndSettle();
      final options = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label?.startsWith('Feminino, cabelo') == true ||
                w.properties.label?.startsWith('Masculino, cabelo') == true),
      );
      expect(options, findsNWidgets(avatarOptions.length));
      final maleCurly = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == 'Masculino, cabelo cacheado 1',
      );
      await tester.ensureVisible(maleCurly);
      await tester.tap(maleCurly);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salvar perfil'));
      await tester.tap(find.text('Salvar perfil'));
      await tester.pumpAndSettle();
      expect(state.active.avatar, 7);
      await state.flush();
      final restored = DuoState(state.store, clock: state.clock);
      await restored.load();
      expect(restored.active.avatar, 7);
      expect(tester.takeException(), isNull);
    },
  );

  appTest('today tasks refresh when returning on a different day', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 26, 12);
    final state = await makeState(clock: () => now);
    task(state, due: DateTime(2026, 10, 27));
    await start(tester, state: state);
    await tester.tap(find.text('Tarefas').last);
    await tester.pumpAndSettle();
    expect(find.text('0 tarefas para hoje'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    now = DateTime(2026, 10, 27, 12);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('1 tarefa para hoje'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  appTest('the open app refreshes automatically at midnight', (tester) async {
    var now = DateTime(2026, 10, 26, 23, 59);
    final state = await makeState(clock: () => now);
    task(state, due: DateTime(2026, 10, 27));
    await start(tester, state: state);
    await tester.tap(find.text('Tarefas').last);
    await tester.pumpAndSettle();
    expect(find.text('0 tarefas para hoje'), findsOneWidget);
    now = DateTime(2026, 10, 27, 0, 1);
    await tester.pump(const Duration(minutes: 2));
    await tester.pumpAndSettle();
    expect(find.text('1 tarefa para hoje'), findsOneWidget);
  });

  for (final width in [320.0, 430.0]) {
    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      appTest('five screens and avatar editor fit at $width in $theme', (
        tester,
      ) async {
        final state = await makeState();
        task(state);
        await start(
          tester,
          state: state,
          width: width,
          height: 932,
          theme: theme,
        );
        for (final tab in [
          'Início',
          'Tarefas',
          'Ranking',
          'Recompensas',
          'Perfil',
        ]) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$tab / $width / $theme',
          );
        }
        await tester.tap(find.byTooltip('Editar meu perfil'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Salvar perfil'));
        expect(tester.takeException(), isNull);
      });
    }
  }

  appTest('visible Android controls meet minimum tap target sizes', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      final state = await makeState();
      task(state);
      await start(tester, state: state, width: 320, height: 932);
      for (final tab in [
        'Início',
        'Tarefas',
        'Ranking',
        'Recompensas',
        'Perfil',
      ]) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        await expectLater(
          tester,
          meetsGuideline(androidTapTargetGuideline),
          reason: tab,
        );
      }
    } finally {
      handle.dispose();
    }
  });

  appTest('desktop navigation keeps the same points and screens', (
    tester,
  ) async {
    final state = await start(tester, width: 1440, height: 1000);
    await tester.tap(find.text('Ranking').last);
    await tester.pumpAndSettle();
    expect(find.text('Desempenho por categoria'), findsOneWidget);
    expect(state.points('ana'), 0);
    expect(tester.takeException(), isNull);
  });
  appTest('all five screens support text at 200 percent on 320px', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final state = await makeState();
    task(state);
    await start(tester, state: state, width: 320, height: 932);
    for (final tab in [
      'Início',
      'Tarefas',
      'Ranking',
      'Recompensas',
      'Perfil',
    ]) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
  });
}
