import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/art.dart';
import '../widgets/components.dart';
import '../widgets/editors.dart';
import '../widgets/panels.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context) {
    final state = DuoScope.of(context);
    final p = Palette.of(context);
    final current = state.xp(state.active.id) % 500;
    final tasks = state.todayTasks;
    return ListView(
      key: const PageStorageKey('home'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        ScreenHeader(
          'Olá, ${state.active.name}!',
          greeting: true,
          subtitle: 'Vamos cuidar da casa juntos!',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NotificationBell(),
              const SizedBox(width: 6),
              Tooltip(
                message: 'A nossa dupla',
                child: InkWell(
                  onTap: () => showDuo(context),
                  customBorder: const CircleBorder(),
                  child: Avatar(state.active, size: 43),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          gradient: p.hero,
          border: false,
          padding: const EdgeInsets.fromLTRB(8, 16, 18, 16),
          child: Row(
            children: [
              const HouseMascot(size: 112),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Nível ${state.level(state.active.id)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        ...List.generate(
                          3,
                          (i) => Icon(
                            Icons.star_rounded,
                            size: 17,
                            color: i == 0 ? Brand.lilac : p.track,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ProgressLine(
                      current / 500,
                      height: 10,
                      colors: const [Brand.blue, Brand.lilac],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$current / 500 XP',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Cada cuidado faz você crescer.',
                      style: TextStyle(fontSize: 10, color: p.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                art: 'coin',
                value: '${state.coins(state.active.id)}',
                label: 'Moedas',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                art: 'fire',
                value: '${state.streak(state.active.id)}',
                label: 'Dias seguidos',
              ),
            ),
          ],
        ),
        SectionTitle(
          'Tarefas de hoje',
          action: 'Ver todas',
          onAction: () => onNavigate(1),
        ),
        if (tasks.isEmpty)
          EmptyState(
            title: 'Tudo em dia por aqui!',
            message: 'A casa agradece. Que tal aproveitar uma pausa?',
            art: 'sleep',
            action: 'Criar uma tarefa',
            onAction: () => showTaskEditor(context),
          )
        else
          ...tasks
              .take(3)
              .map(
                (t) => TaskTile(
                  t,
                  quickComplete: true,
                  onTap: () => showTaskDetails(context, t),
                ),
              ),
        const SizedBox(height: 5),
        const GoalCard(),
        SectionTitle(
          'Juntos, a gente vai mais longe',
          action: 'Ranking',
          onAction: () => onNavigate(2),
        ),
        AppCard(
          onTap: () => showDuo(context),
          child: Row(
            children: [
              Avatar(state.active, size: 38),
              const SizedBox(width: 7),
              Avatar(state.partner, size: 38),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uma dupla, uma casa mais leve',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${state.weeklyCount} tarefas feitas em dupla nesta semana',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.favorite_rounded, color: Brand.lilac, size: 21),
            ],
          ),
        ),
        SectionTitle(
          'Atividade recente',
          action: 'Ver tudo',
          onAction: () => showActivities(context),
        ),
        ...state.activities
            .take(3)
            .map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(
                  children: [
                    Art(a.art, size: 29),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.text,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
