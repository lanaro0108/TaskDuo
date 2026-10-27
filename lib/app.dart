import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'domain/duo_state.dart';
import 'domain/models.dart';
import 'ui/theme.dart';
import 'ui/widgets/art.dart';
import 'ui/widgets/components.dart';
import 'ui/widgets/panels.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/tasks_screen.dart';
import 'ui/screens/ranking_screen.dart';
import 'ui/screens/rewards_screen.dart';
import 'ui/screens/profile_screen.dart';

class TaskDuoApp extends StatelessWidget {
  const TaskDuoApp({super.key, required this.state});
  final DuoState state;
  @override
  Widget build(BuildContext context) => DuoScope(
    state: state,
    child: ListenableBuilder(
      listenable: state,
      builder: (context, _) => MaterialApp(
        title: 'TaskDuo',
        debugShowCheckedModeBanner: false,
        theme: taskDuoTheme(Brightness.light),
        darkTheme: taskDuoTheme(Brightness.dark),
        themeMode: state.themeMode,
        themeAnimationDuration: Duration(
          milliseconds: state.animations ? 250 : 0,
        ),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const _AppShell(),
      ),
    ),
  );
}

class _AppShell extends StatefulWidget {
  const _AppShell();
  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with WidgetsBindingObserver {
  int _selected = 0;
  DuoState? _state;
  Timer? _dayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = DuoScope.of(context);
    if (!identical(state, _state)) {
      _state = state;
      _scheduleDayRefresh();
    }
  }

  void _scheduleDayRefresh() {
    _dayTimer?.cancel();
    final now = _state!.clock();
    final delay = addCalendarDays(now, 1).difference(now);
    _dayTimer = Timer(delay + const Duration(milliseconds: 50), () {
      if (!mounted) return;
      _state!.refreshDate();
      _scheduleDayRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _state?.refreshDate();
      if (_state != null) _scheduleDayRefresh();
    } else {
      _dayTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayTimer?.cancel();
    super.dispose();
  }

  static const _labels = [
    'Início',
    'Tarefas',
    'Ranking',
    'Recompensas',
    'Perfil',
  ];
  static const _icons = [
    Icons.home_outlined,
    Icons.assignment_outlined,
    Icons.emoji_events_outlined,
    Icons.card_giftcard_rounded,
    Icons.person_outline_rounded,
  ];
  static const _activeIcons = [
    Icons.home_rounded,
    Icons.assignment_rounded,
    Icons.emoji_events_rounded,
    Icons.redeem_rounded,
    Icons.person_rounded,
  ];
  void _navigate(int value) => setState(() => _selected = value);
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final state = DuoScope.of(context);
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.dark
          ? SystemUiOverlayStyle.light.copyWith(
              systemNavigationBarColor: p.surface,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              systemNavigationBarColor: p.surface,
            ),
      child: Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              if (desktop) _sidebar(context),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      children: [
                        if (state.persistenceError != null)
                          MaterialBanner(
                            content: Text(
                              state.persistenceError!,
                              style: const TextStyle(fontSize: 12),
                            ),
                            leading: const Icon(Icons.warning_amber_rounded),
                            actions: [
                              TextButton(
                                onPressed:
                                    state.persistenceError!.contains('ler')
                                    ? state.load
                                    : state.retrySave,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        Expanded(
                          child: IndexedStack(
                            index: _selected,
                            children: [
                              HomeScreen(onNavigate: _navigate),
                              const TasksScreen(),
                              const RankingScreen(),
                              RewardsScreen(onNavigate: _navigate),
                              const ProfileScreen(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: desktop
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: p.surface,
                    border: Border(top: BorderSide(color: p.line)),
                  ),
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
                  child: Row(
                    children: List.generate(
                      5,
                      (i) => Expanded(
                        child: Semantics(
                          selected: _selected == i,
                          button: true,
                          label: 'Aba ${_labels[i]}',
                          child: InkWell(
                            onTap: () => _navigate(i),
                            borderRadius: BorderRadius.circular(15),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: Duration(
                                      milliseconds: state.animations ? 180 : 0,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selected == i
                                          ? Brand.purple.withValues(alpha: .1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(
                                      _selected == i
                                          ? _activeIcons[i]
                                          : _icons[i],
                                      size: 23,
                                      color: _selected == i
                                          ? (p.dark
                                                ? const Color(0xffa69aff)
                                                : Brand.purple)
                                          : p.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _labels[i],
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: _selected == i
                                          ? FontWeight.w900
                                          : FontWeight.w600,
                                      color: _selected == i
                                          ? (p.dark
                                                ? const Color(0xffb3a8ff)
                                                : Brand.purple)
                                          : p.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _sidebar(BuildContext context) {
    final state = DuoScope.of(context), p = Palette.of(context);
    return Container(
      width: 238,
      padding: const EdgeInsets.fromLTRB(23, 30, 23, 22),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(right: BorderSide(color: p.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandMark(size: 53),
          const SizedBox(height: 11),
          ShaderMask(
            shaderCallback: (r) =>
                const LinearGradient(colors: [Brand.blue, Brand.lilac])
                    .createShader(r),
            child: const Text(
              'TaskDuo',
              style: TextStyle(
                fontSize: 32,
                letterSpacing: -1.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Juntos por uma casa\nmais organizada.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 44),
          ...List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  onTap: () => _navigate(i),
                  selected: _selected == i,
                  selectedTileColor: p.tint,
                  selectedColor: p.dark
                      ? const Color(0xffb7abff)
                      : Brand.purple,
                  iconColor: p.muted,
                  textColor: p.muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                  leading: Icon(
                    _selected == i ? _activeIcons[i] : _icons[i],
                    size: 22,
                  ),
                  title: Text(
                    _labels[i],
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          AppCard(
            padding: const EdgeInsets.all(12),
            onTap: () => showDuo(context),
            child: Row(
              children: [
                Avatar(state.active, size: 37),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.active.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'A nossa dupla',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.unfold_more_rounded, size: 17),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              IconButton(
                tooltip: 'Alterar tema',
                onPressed: () => showThemePicker(context),
                icon: Icon(
                  p.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  color: p.muted,
                  size: 19,
                ),
              ),
              Text(
                'Um lar mais leve',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
