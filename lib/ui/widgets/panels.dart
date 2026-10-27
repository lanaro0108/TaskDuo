import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme.dart';
import 'art.dart';
import 'components.dart';
import 'editors.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.greeting = false,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool greeting;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 24),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: greeting
                          ? Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontSize: 24)
                          : Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (greeting)
                    const Padding(
                      padding: EdgeInsets.only(left: 7),
                      child: Icon(
                        Icons.waving_hand_rounded,
                        size: 22,
                        color: Brand.gold,
                      ),
                    ),
                ],
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing! else const NotificationBell(),
      ],
    ),
  );
}

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});
  @override
  Widget build(BuildContext context) {
    final state = DuoScope.of(context);
    return IconButton(
      tooltip: 'Atividade da casa',
      onPressed: () => showActivities(context),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 26,
            color: Palette.of(context).ink,
          ),
          if (state.notifications && state.activities.isNotEmpty)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xfff48aaa),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Palette.of(context).background,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showActivities(BuildContext context) => duoSheet<void>(
  context,
  Builder(
    builder: (c) {
      final state = DuoScope.of(c);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeading(
            'Aconteceu por aqui',
            subtitle: 'Cada cuidado conta na história da sua casa.',
          ),
          if (state.activities.isEmpty)
            const EmptyState(
              title: 'Uma história para começar',
              message: 'As atividades da dupla vão aparecer aqui.',
            )
          else
            ...state.activities
                .take(30)
                .map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Art(a.art, size: 36),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.text,
                                style: Theme.of(c).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${shortDate(a.at)} · ${a.at.hour.toString().padLeft(2, '0')}:${a.at.minute.toString().padLeft(2, '0')}',
                                style: Theme.of(c).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      );
    },
  ),
);

Future<void> showDuo(BuildContext context) => duoSheet<void>(
  context,
  Builder(
    builder: (c) {
      final state = DuoScope.of(c);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeading(
            'A nossa dupla',
            subtitle: 'Escolha quem está usando este aparelho.',
          ),
          ...state.members.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () {
                  state.switchMember(m.id);
                  Navigator.pop(c);
                },
                child: Row(
                  children: [
                    Avatar(m, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: Theme.of(c).textTheme.titleMedium,
                          ),
                          Text(
                            'Nível ${state.level(m.id)} · ${state.completedCount(m.id)} tarefas',
                            style: Theme.of(c).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar ${m.name}',
                      onPressed: () {
                        Navigator.pop(c);
                        showMemberEditor(context, m);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    if (m.id == state.active.id)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Brand.purple,
                        size: 21,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Os dois perfis ficam salvos neste aparelho. A conexão entre celulares será adicionada na etapa de sincronização.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    },
  ),
);

Future<void> showThemePicker(BuildContext context) => duoSheet<void>(
  context,
  Builder(
    builder: (c) {
      final state = DuoScope.of(c);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeading(
            'Seu jeito de ver a casa',
            subtitle: 'Um tema para cada momento do seu dia.',
          ),
          ...ThemeMode.values.map(
            (mode) => ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              tileColor: state.themeMode == mode ? Palette.of(c).tint : null,
              leading: Icon(switch (mode) {
                ThemeMode.light => Icons.light_mode_outlined,
                ThemeMode.dark => Icons.dark_mode_outlined,
                ThemeMode.system => Icons.brightness_auto_outlined,
              }),
              title: Text(switch (mode) {
                ThemeMode.light => 'Claro',
                ThemeMode.dark => 'Escuro',
                ThemeMode.system => 'Seguir o sistema',
              }),
              trailing: state.themeMode == mode
                  ? const Icon(Icons.check_circle_rounded, color: Brand.purple)
                  : null,
              onTap: () {
                state.setTheme(mode);
                Navigator.pop(c);
              },
            ),
          ),
        ],
      );
    },
  ),
);

Future<void> showAchievements(BuildContext context) => duoSheet<void>(
  context,
  Builder(
    builder: (c) {
      final state = DuoScope.of(c);
      final achievements = state.achievements(state.active.id);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeading(
            'Pequenas grandes conquistas',
            subtitle:
                '${achievements.where((a) => a.unlocked).length} de ${achievements.length} conquistas desbloqueadas',
          ),
          ...achievements.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  children: [
                    Opacity(
                      opacity: a.unlocked ? 1 : .45,
                      child: Art(a.art, size: 49),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: Theme.of(c).textTheme.titleSmall,
                          ),
                          Text(
                            a.description,
                            style: Theme.of(c).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          ProgressLine(a.progress, height: 5),
                          const SizedBox(height: 4),
                          Text(
                            a.unlocked
                                ? 'Conquistada!'
                                : '${a.current.clamp(0, a.target)}/${a.target}',
                            style: TextStyle(
                              fontSize: 10,
                              color: a.unlocked
                                  ? Brand.mint
                                  : Palette.of(c).muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      a.unlocked
                          ? Icons.verified_rounded
                          : Icons.lock_outline_rounded,
                      size: 20,
                      color: a.unlocked ? Brand.mint : Palette.of(c).muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  ),
);

Future<void> showEvolution(BuildContext context) => duoSheet<void>(
  context,
  Builder(
    builder: (c) {
      final state = DuoScope.of(c);
      final bars = state.weeklyBars(state.active.id);
      final max = math.max(1, bars.reduce(math.max));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeading(
            'Olha o quanto você cresceu',
            subtitle: 'Seu XP nos últimos sete dias. Um cuidado de cada vez.',
          ),
          AppCard(
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      7,
                      (i) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${bars[i]}',
                                style: Theme.of(c).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 7),
                              Container(
                                height: 18 + (bars[i] / max) * 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9),
                                  gradient: LinearGradient(
                                    colors: i == 6
                                        ? [Brand.blue, Brand.purple]
                                        : [
                                            Brand.lilac.withValues(alpha: .5),
                                            Brand.purple.withValues(alpha: .35),
                                          ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                shortDate(
                                  state.today.subtract(Duration(days: 6 - i)),
                                ),
                                style: const TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  '${bars.fold(0, (a, b) => a + b)} XP conquistados em 7 dias',
                  style: Theme.of(c).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'O progresso fica mais leve quando a gente faz junto.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    },
  ),
);
