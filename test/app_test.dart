import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskduo/app.dart';
import 'package:taskduo/domain/duo_state.dart';

import 'test_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
    await font.load();
  });
  Future<DuoState> start(
    WidgetTester tester, {
    double width = 430,
    double height = 932,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = DuoState(
      TestStore(),
      clock: () => DateTime(2026, 10, 26, 12),
    );
    await state.load();
    state.setAnimations(false);
    await state.flush();
    await tester.pumpWidget(TaskDuoApp(state: state));
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets(
    'home completion updates the actual balance and removes today task',
    (tester) async {
      final state = await start(tester);
      expect(find.text('Olá, Ana!'), findsOneWidget);
      await tester.tap(find.byTooltip('Concluir Lavar a louça'));
      await tester.pumpAndSettle();
      expect(state.coins('ana'), 125);
      expect(state.xp('ana'), 2340);
      expect(find.text('Lavar a louça'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('create, search and complete a task through the interface', (
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
    await tester.ensureVisible(find.text('Criar tarefa'));
    await tester.tap(find.text('Criar tarefa'));
    await tester.pumpAndSettle();
    expect(
      state.tasks.where((t) => t.title == 'Regar as plantas'),
      hasLength(1),
    );
    await tester.enterText(find.byType(TextField).first, 'regar');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regar as plantas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir tarefa'));
    await tester.pumpAndSettle();
    expect(
      state.tasks.firstWhere((t) => t.title == 'Regar as plantas').done,
      isTrue,
    );
    expect(find.text('Nenhuma tarefa por aqui'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'reward confirmation debits coins and history can be marked used',
    (tester) async {
      final state = await start(tester);
      await tester.tap(find.text('Recompensas').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escolher o filme da noite').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resgatar por 50 moedas'));
      await tester.pumpAndSettle();
      expect(state.coins('ana'), 70);
      await tester.tap(find.text('Resgatadas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar como usada'));
      await tester.pumpAndSettle();
      expect(state.redemptions.single.used, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'theme changes from profile and each mobile screen fits at 320px',
    (tester) async {
      final state = await start(tester, width: 320, height: 780);
      for (final tab in ['Tarefas', 'Ranking', 'Recompensas', 'Perfil']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Layout for $tab');
      }
      await tester.scrollUntilVisible(find.text('Tema do app'), 200);
      await tester.tap(find.text('Tema do app'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escuro'));
      await tester.pumpAndSettle();
      expect(state.themeMode, ThemeMode.dark);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('desktop navigation retains the same functioning application', (
    tester,
  ) async {
    final state = await start(tester, width: 1440, height: 1000);
    expect(find.text('TaskDuo'), findsOneWidget);
    await tester.tap(find.text('Ranking').last);
    await tester.pumpAndSettle();
    expect(find.text('Desempenho por categoria'), findsOneWidget);
    expect(state.coins('ana'), 120);
    expect(tester.takeException(), isNull);
  });
}
