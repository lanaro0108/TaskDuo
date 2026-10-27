import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/duo_state.dart';
import '../../domain/models.dart';
import '../theme.dart';
import 'art.dart';

class DuoScope extends InheritedNotifier<DuoState> {
  const DuoScope({super.key, required DuoState state, required super.child})
    : super(notifier: state);
  static DuoState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DuoScope>()!.notifier!;
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.color,
    this.onTap,
    this.border = true,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradient;
  final Color? color;
  final VoidCallback? onTap;
  final bool border;
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: p.dark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xff7670bd).withValues(alpha: .045),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: gradient == null ? color ?? p.surface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border ? p.line : Colors.transparent),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: gradient == null
              ? null
              : BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
          child: Semantics(
            button: onTap != null,
            child: InkWell(
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(left: 8),
              minimumSize: const Size(0, 32),
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16),
              ],
            ),
          ),
      ],
    ),
  );
}

class ProgressLine extends StatelessWidget {
  const ProgressLine(
    this.value, {
    super.key,
    this.height = 9,
    this.colors = const [Brand.purple, Brand.lilac],
  });
  final double value, height;
  final List<Color> colors;
  @override
  Widget build(BuildContext context) => Semantics(
    value: '${(value.clamp(0, 1) * 100).round()}%',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: Palette.of(context).track,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: value.clamp(0, 1)),
            duration: Duration(
              milliseconds: DuoScope.of(context).animations ? 500 : 0,
            ),
            builder: (context, v, _) => Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: v,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SizedBox(height: height),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class CoinLabel extends StatelessWidget {
  const CoinLabel(this.value, {super.key, this.suffix = '', this.size = 14});
  final int value;
  final String suffix;
  final double size;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Art('coin', size: size + 8),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          '$value$suffix',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            color: Palette.of(context).ink,
          ),
        ),
      ),
    ],
  );
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.art,
    required this.value,
    required this.label,
    this.compact = false,
  });
  final String art, value, label;
  final bool compact;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 13),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Art(art, size: compact ? 27 : 35),
        SizedBox(width: compact ? 6 : 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: compact ? 16 : 21,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  color: Palette.of(context).ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  color: Palette.of(context).muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class Segments extends StatelessWidget {
  const Segments({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });
  final List<String> items;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.raised,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(
          items.length,
          (i) => Expanded(
            child: Semantics(
              selected: selected == i,
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(21),
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: Duration(
                    milliseconds: DuoScope.of(context).animations ? 180 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21),
                    gradient: i == selected
                        ? const LinearGradient(
                            colors: [Color(0xff9d91ff), Brand.purple],
                          )
                        : null,
                    boxShadow: i == selected
                        ? [
                            BoxShadow(
                              color: Brand.purple.withValues(alpha: .15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    items[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: i == selected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: i == selected ? Colors.white : p.muted,
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
}

class TaskSticker extends StatelessWidget {
  const TaskSticker(this.category, {super.key, this.size = 46});
  final TaskCategory category;
  final double size;
  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xffb4e4ff),
      const Color(0xffe4d1ff),
      const Color(0xffb9ecf8),
      const Color(0xffffdec3),
      const Color(0xffcaddeb),
    ];
    final color = colors[category.index];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: Palette.of(context).dark ? .18 : .7),
            color.withValues(alpha: Palette.of(context).dark ? .08 : .3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: category == TaskCategory.kitchen
          ? Icon(
              Icons.local_laundry_service_rounded,
              size: size * .76,
              color: Palette.of(context).dark
                  ? const Color(0xff9cd6ff)
                  : const Color(0xff68b7fb),
              shadows: [
                Shadow(
                  color: Brand.blue.withValues(alpha: .25),
                  offset: const Offset(1, 2),
                  blurRadius: 3,
                ),
              ],
            )
          : Art(category.art, size: size * .91),
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile(
    this.task, {
    super.key,
    required this.onTap,
    this.quickComplete = false,
  });
  final HouseTask task;
  final VoidCallback onTap;
  final bool quickComplete;
  @override
  Widget build(BuildContext context) {
    final state = DuoScope.of(context);
    final p = Palette.of(context);
    final late = !task.done && dayOnly(task.due).isBefore(state.today);
    final isToday = dayOnly(task.due) == state.today;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
        child: Row(
          children: [
            TaskSticker(task.category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      decoration: task.done ? TextDecoration.lineThrough : null,
                      color: task.done ? p.muted : p.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.category.label} · ${task.xp} XP',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Avatar(state.member(task.memberId), size: 27),
            const SizedBox(width: 6),
            if (quickComplete || task.done)
              IconButton(
                tooltip: task.done
                    ? 'Tarefa concluída'
                    : 'Concluir ${task.title}',
                visualDensity: VisualDensity.compact,
                onPressed: task.done ? null : () => finishTask(context, task),
                icon: Icon(
                  task.done
                      ? Icons.check_circle_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: task.done ? Brand.mint : p.track,
                  size: 25,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: late
                      ? const Color(0xffffe4e8)
                            .withValues(alpha: p.dark ? .13 : 1)
                      : isToday
                      ? Brand.blue.withValues(alpha: .12)
                      : p.raised,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  late
                      ? 'Atrasada'
                      : isToday
                      ? 'Hoje'
                      : shortDate(task.due),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: late
                        ? const Color(0xffdc7188)
                        : isToday
                        ? (p.dark ? const Color(0xff9abbff) : Brand.blue)
                        : p.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 3)),
    );
}

void finishTask(BuildContext context, HouseTask task) {
  final state = DuoScope.of(context);
  final oldLevel = state.level(task.memberId);
  final completion = state.completeTask(task.id);
  if (completion == null) return;
  if (state.sounds) {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }
  final prefix = state.level(task.memberId) > oldLevel
      ? 'Nível ${state.level(task.memberId)} desbloqueado! '
      : 'Muito bem, ${state.member(task.memberId).name}! ';
  toast(context, '$prefix+${completion.xp} XP e +${completion.coins} moedas.');
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.art = 'sparkles',
    this.action,
    this.onAction,
  });
  final String title, message, art;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
    child: Column(
      children: [
        Art(art, size: 74),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center),
        if (action != null)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: FilledButton(onPressed: onAction, child: Text(action!)),
          ),
      ],
    ),
  );
}

class GoalCard extends StatelessWidget {
  const GoalCard({super.key});
  @override
  Widget build(BuildContext context) {
    final state = DuoScope.of(context);
    return AppCard(
      gradient: Palette.of(context).hero,
      border: false,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.challengeClaimed
                      ? 'Desafio concluído!'
                      : 'Desafio da semana',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  state.challengeClaimed
                      ? '+50 moedas para cada. Vocês arrasaram!'
                      : 'Concluir 10 tarefas em dupla',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ProgressLine(state.weeklyCount / 10, height: 10),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${state.weeklyCount.clamp(0, 10)}/10',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Art('gift', size: 61),
        ],
      ),
    );
  }
}

Future<T?> duoSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(c).height * .88,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
              child: child,
            ),
          ),
        ),
      ),
    );

class SheetHeading extends StatelessWidget {
  const SheetHeading(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(subtitle!),
          ),
      ],
    ),
  );
}
