import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme.dart';
import 'art.dart';
import 'components.dart';

Future<void> showTaskEditor(BuildContext context, {HouseTask? task}) =>
    duoSheet<void>(context, TaskEditor(task: task));

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, this.task});
  final HouseTask? task;
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(
    text: widget.task?.title,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.task?.description,
  );
  TaskCategory? _category;
  Difficulty? _difficulty;
  Recurrence? _recurrence;
  String? _memberId;
  DateTime? _due;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = DuoScope.of(context);
    _category ??= widget.task?.category ?? TaskCategory.kitchen;
    _difficulty ??= widget.task?.difficulty ?? Difficulty.easy;
    _recurrence ??= widget.task?.recurrence ?? Recurrence.none;
    _memberId ??= widget.task?.memberId ?? state.active.id;
    _due ??= widget.task?.due ?? state.today;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeading(
            widget.task == null ? 'Uma nova missão' : 'Editar tarefa',
            subtitle: 'Pequenos cuidados fazem uma grande diferença.',
          ),
          TextFormField(
            controller: _title,
            maxLength: 70,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome da tarefa',
              hintText: 'Ex.: regar as plantas',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Dê um nome à tarefa.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            maxLines: 2,
            maxLength: 240,
            decoration: const InputDecoration(
              labelText: 'Descrição (opcional)',
              hintText: 'Algum cuidado especial?',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskCategory>(
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: TaskCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _memberId,
            decoration: const InputDecoration(labelText: 'Responsável'),
            items: state.members
                .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                .toList(),
            onChanged: (v) => setState(() => _memberId = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Difficulty>(
            initialValue: _difficulty,
            decoration: const InputDecoration(labelText: 'Dificuldade'),
            items: Difficulty.values
                .map(
                  (d) => DropdownMenuItem(
                    value: d,
                    child: Text('${d.label} · ${d.xp} pontos'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _difficulty = v),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: _due!,
                firstDate: DateTime(state.today.year - 1),
                lastDate: DateTime(state.today.year + 5),
                helpText: 'Quando vamos cuidar disso?',
              );
              if (selected != null && mounted) setState(() => _due = selected);
            },
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text('Prazo: ${shortDate(_due!)}'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Recurrence>(
            initialValue: _recurrence,
            decoration: const InputDecoration(labelText: 'Repetir'),
            items: Recurrence.values
                .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                .toList(),
            onChanged: (v) => setState(() => _recurrence = v),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              state.saveTask(
                existing: widget.task,
                title: _title.text,
                description: _description.text,
                memberId: _memberId!,
                category: _category!,
                difficulty: _difficulty!,
                due: _due!,
                recurrence: _recurrence!,
              );
              Navigator.pop(context);
              toast(
                context,
                widget.task == null
                    ? 'Nova missão adicionada à casa!'
                    : 'Tarefa atualizada.',
              );
            },
            icon: const Icon(Icons.check_rounded),
            label: Text(
              widget.task == null ? 'Criar tarefa' : 'Salvar alterações',
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showTaskDetails(BuildContext context, HouseTask task) async {
  final state = DuoScope.of(context);
  final futureRecurring =
      task.recurrence != Recurrence.none &&
      dayOnly(task.due).isAfter(state.today);
  await duoSheet<void>(
    context,
    Builder(
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: TaskSticker(task.category, size: 72)),
          const SizedBox(height: 18),
          SheetHeading(
            task.title,
            subtitle: task.description.isEmpty
                ? 'Um cuidado a mais para a nossa casa.'
                : task.description,
          ),
          AppCard(
            child: Column(
              children: [
                _Detail('Responsável', state.member(task.memberId).name),
                _Detail('Categoria', task.category.label),
                _Detail('Dificuldade', task.difficulty.label),
                _Detail('Prazo', shortDate(task.due)),
                _Detail('Frequência', task.recurrence.label),
                _Detail('Você ganha', '${task.xp} pontos e ${task.xp} XP'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!task.done) ...[
            FilledButton.icon(
              onPressed: futureRecurring
                  ? null
                  : () {
                      Navigator.pop(sheetContext);
                      finishTask(context, task);
                    },
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                futureRecurring
                    ? 'Disponível em ${shortDate(task.due)}'
                    : 'Concluir tarefa',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                showTaskEditor(context, task: task);
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar ou trocar responsável'),
            ),
          ] else
            const Center(
              child: Text(
                'Missão cumprida. Muito bem!',
                style: TextStyle(
                  color: Brand.mint,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              final approved = await showDialog<bool>(
                context: sheetContext,
                builder: (c) => AlertDialog(
                  title: const Text('Excluir esta tarefa?'),
                  content: const Text(
                    'A tarefa será removida da lista. Os pontos já conquistados permanecem no histórico.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Manter tarefa'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              );
              if (approved == true && sheetContext.mounted) {
                state.deleteTask(task.id);
                Navigator.pop(sheetContext);
                if (context.mounted) toast(context, 'Tarefa excluída.');
              }
            },
            child: Text(
              'Excluir tarefa',
              style: TextStyle(color: Theme.of(sheetContext).colorScheme.error),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail(this.name, this.value);
  final String name, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(name),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    ),
  );
}

Future<void> showRewardEditor(BuildContext context) =>
    duoSheet<void>(context, const RewardEditor());

class RewardEditor extends StatefulWidget {
  const RewardEditor({super.key});
  @override
  State<RewardEditor> createState() => _RewardEditorState();
}

class _RewardEditorState extends State<RewardEditor> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController();
  String _art = 'gift';
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHeading(
          'Uma nova recompensa',
          subtitle: 'O melhor prêmio é aquele que combina com vocês.',
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: ['gift', 'popcorn', 'icecream', 'sleep', 'music', 'sofa']
              .map(
                (art) => InkWell(
                  onTap: () => setState(() => _art = art),
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _art == art ? Palette.of(context).tint : null,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _art == art ? Brand.purple : Colors.transparent,
                      ),
                    ),
                    child: Art(art, size: 37),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _title,
          maxLength: 70,
          decoration: const InputDecoration(labelText: 'Nome da recompensa'),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Dê um nome à recompensa.' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _description,
          maxLength: 160,
          decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            DuoScope.of(context)
                .addReward(_title.text, _description.text, _art);
            Navigator.pop(context);
            toast(
              context,
              'Recompensa criada. Mais um motivo para cuidar da casa!',
            );
          },
          child: const Text('Criar recompensa'),
        ),
      ],
    ),
  );
}

Future<void> showMemberEditor(BuildContext context, Member member) =>
    duoSheet<void>(context, MemberEditor(member));

class MemberEditor extends StatefulWidget {
  const MemberEditor(this.member, {super.key});
  final Member member;
  @override
  State<MemberEditor> createState() => _MemberEditorState();
}

class _MemberEditorState extends State<MemberEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.member.name);
  late var _avatar = widget.member.avatar;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHeading(
          'Seu jeitinho de ser',
          subtitle: 'Personalize seu nome e seu avatar.',
        ),
        for (final masculine in [false, true]) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 10),
            child: Text(
              masculine ? 'Masculinos' : 'Femininos',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < avatarOptions.length; i++)
                if (avatarOptions[i].masculine == masculine)
                  Semantics(
                    label: avatarOptions[i].label,
                    selected: _avatar == i,
                    button: true,
                    excludeSemantics: true,
                    onTap: () => setState(() => _avatar = i),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _avatar = i),
                      child: Container(
                        width: 76,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _avatar == i ? Palette.of(context).tint : null,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _avatar == i
                                ? Brand.purple
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Avatar(widget.member.copyWith(avatar: i), size: 54),
                            const SizedBox(height: 5),
                            Text(
                              avatarOptions[i].label.split('cabelo ').last,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ],
        const SizedBox(height: 22),
        TextFormField(
          controller: _name,
          maxLength: 24,
          decoration: const InputDecoration(
            labelText: 'Como podemos chamar você?',
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Conte seu nome para a gente.'
              : null,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            DuoScope.of(context)
                .editMember(widget.member.id, _name.text, _avatar);
            Navigator.pop(context);
          },
          child: const Text('Salvar perfil'),
        ),
      ],
    ),
  );
}
