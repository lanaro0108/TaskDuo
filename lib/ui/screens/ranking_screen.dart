import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme.dart';
import '../widgets/art.dart';
import '../widgets/components.dart';
import '../widgets/panels.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});
  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  int _period = 0;
  @override
  Widget build(BuildContext context) {
    final state = DuoScope.of(context);
    final p = Palette.of(context);
    final own = state.periodXp(state.active.id, _period),
        other = state.periodXp(state.partner.id, _period);
    final ownCompletions = state.inPeriod(_period, id: state.active.id);
    final badges = state.achievements(state.active.id).take(4).toList();
    return ListView(
      key: const PageStorageKey('ranking'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        const ScreenHeader('Ranking'),
        Segments(
          items: const ['Semana', 'Mês', 'Geral'],
          selected: _period,
          onChanged: (i) => setState(() => _period = i),
        ),
        const SizedBox(height: 18),
        AppCard(
          gradient: p.hero,
          border: false,
          padding: const EdgeInsets.all(19),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _Contender(
                      state.active,
                      points: own,
                      label: 'Você',
                      winner: own >= other && own > 0,
                    ),
                  ),
                  Container(
                    width: 37,
                    height: 37,
                    decoration: BoxDecoration(
                      color: p.surface.withValues(alpha: .45),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: p.ink,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _Contender(
                      state.partner,
                      points: other,
                      label: state.partner.name,
                      winner: other > own,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  height: 11,
                  child: Row(
                    children: [
                      Expanded(
                        flex: math.max(1, own),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xff45c5ff), Brand.blue],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: math.max(1, other),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Brand.lilac, Color(0xffc3a2ff)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Text(
                own == other
                    ? 'Em sintonia! A dupla está empatada.'
                    : own > other
                    ? 'Você está ${own - other} XP à frente. Continue assim!'
                    : '${state.partner.name} está ${other - own} XP à frente. Vamos lá!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: StatCard(
                art: 'bubble',
                value: '${ownCompletions.length}',
                label: 'Tarefas',
                compact: true,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: StatCard(
                art: 'sparkles',
                value: '$own',
                label: 'XP',
                compact: true,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: StatCard(
                art: 'coin',
                value: '${state.coins(state.active.id)}',
                label: 'Moedas',
                compact: true,
              ),
            ),
          ],
        ),
        SectionTitle(
          'Conquistas',
          action: 'Ver todas',
          onAction: () => showAchievements(context),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            badges.length,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                child: AppCard(
                  onTap: () => showAchievements(context),
                  color: p.tint.withValues(alpha: p.dark ? .5 : 1),
                  border: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 13,
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Opacity(
                            opacity: badges[i].unlocked ? 1 : .45,
                            child: Art(badges[i].art, size: 45),
                          ),
                          if (!badges[i].unlocked)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Icon(
                                Icons.lock_rounded,
                                size: 13,
                                color: p.muted,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        badges[i].title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SectionTitle('Desempenho por categoria'),
        AppCard(
          child: Column(
            children: TaskCategory.values.map((cat) {
              final count = ownCompletions
                  .where((c) => c.category == cat)
                  .length;
              final value = ownCompletions.isEmpty
                  ? 0.0
                  : count / ownCompletions.length;
              final colors = [
                [Brand.blue, const Color(0xff80deee)],
                [Brand.purple, Brand.lilac],
                [Brand.lilac, const Color(0xffcfafff)],
                [const Color(0xffa3a5ff), const Color(0xffc8bfff)],
                [Brand.mint, const Color(0xffb3eedc)],
              ][cat.index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Art(cat.art, size: 22),
                    const SizedBox(width: 7),
                    SizedBox(
                      width: 61,
                      child: Text(
                        cat.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: ProgressLine(value, height: 10, colors: colors),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${(value * 100).round()}%',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_rounded, color: Brand.lilac, size: 15),
            const SizedBox(width: 7),
            Text(
              'A maior conquista é fazer juntos.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _Contender extends StatelessWidget {
  const _Contender(
    this.member, {
    required this.points,
    required this.label,
    required this.winner,
  });
  final Member member;
  final int points;
  final String label;
  final bool winner;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 24,
        child: winner ? const Art('trophy', size: 25) : null,
      ),
      Avatar(member, size: 78, ring: true),
      const SizedBox(height: 8),
      Text(
        label,
        style: Theme.of(context).textTheme.titleSmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 3),
      Text(
        '$points XP',
        style: TextStyle(
          color: Palette.of(context).dark
              ? const Color(0xffbeb3ff)
              : const Color(0xff6050d4),
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}
