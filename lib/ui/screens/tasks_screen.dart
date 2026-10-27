import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme.dart';
import '../widgets/components.dart';
import '../widgets/editors.dart';
import '../widgets/panels.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _search = TextEditingController();
  int _tab = 0, _sort = 0;
  String _owner = 'all', _category = 'all', _difficulty = 'all';
  bool get _filtered =>
      _owner != 'all' ||
      _category != 'all' ||
      _difficulty != 'all' ||
      _sort != 0;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[áàãâ]'), 'a')
      .replaceAll(RegExp('[éê]'), 'e')
      .replaceAll('í', 'i')
      .replaceAll(RegExp('[óôõ]'), 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');
  @override
  Widget build(BuildContext context) {
    final state = DuoScope.of(context);
    final p = Palette.of(context);
    final tasks =
        state.tasks.where((t) {
          final tabMatch = switch (_tab) {
            0 => !t.done && !dayOnly(t.due).isAfter(state.today),
            1 => !t.done,
            2 => !t.done && t.recurrence != Recurrence.none,
            _ => t.done,
          };
          return tabMatch &&
              (_owner == 'all' || _owner == t.memberId) &&
              (_category == 'all' || _category == t.category.name) &&
              (_difficulty == 'all' || _difficulty == t.difficulty.name) &&
              _normalize('${t.title} ${t.description} ${t.category.label}')
                  .contains(_normalize(_search.text.trim()));
        }).toList()..sort(
          (a, b) => _sort == 1
              ? b.xp.compareTo(a.xp)
              : _sort == 2
              ? a.title.compareTo(b.title)
              : a.due.compareTo(b.due),
        );
    return Stack(
      children: [
        ListView(
          key: const PageStorageKey('tasks'),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 105),
          children: [
            const ScreenHeader('Tarefas'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar tarefas...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: p.muted,
                        size: 21,
                      ),
                      suffixIcon: _search.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                IconButton.filledTonal(
                  tooltip: 'Filtrar e ordenar tarefas',
                  onPressed: _showFilters,
                  style: IconButton.styleFrom(
                    backgroundColor: _filtered ? Brand.purple : p.raised,
                    foregroundColor: _filtered ? Colors.white : p.ink,
                    fixedSize: const Size(47, 47),
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Segments(
              items: const ['Hoje', 'Pendentes', 'Recorrentes', 'Concluídas'],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${tasks.length} ${tasks.length == 1 ? 'tarefa' : 'tarefas'}${_tab == 0 ? ' para hoje' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (_filtered)
                  TextButton(
                    onPressed: () => setState(() {
                      _owner = 'all';
                      _category = 'all';
                      _difficulty = 'all';
                      _sort = 0;
                    }),
                    child: const Text(
                      'Limpar filtros',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (tasks.isEmpty)
              EmptyState(
                title: _search.text.isNotEmpty || _filtered
                    ? 'Nenhuma tarefa por aqui'
                    : _tab == 3
                    ? 'Sua primeira missão espera por você'
                    : 'Tudo tranquilo por aqui',
                message: _search.text.isNotEmpty || _filtered
                    ? 'Tente outra busca ou ajuste os filtros.'
                    : _tab == 3
                    ? 'As tarefas concluídas vão aparecer aqui.'
                    : 'Adicione uma tarefa e divida os cuidados com a casa.',
                art: _tab == 3 ? 'star' : 'broom',
                action: _search.text.isEmpty && !_filtered
                    ? 'Criar tarefa'
                    : null,
                onAction: () => showTaskEditor(context),
              )
            else
              ...tasks.map(
                (t) => TaskTile(t, onTap: () => showTaskDetails(context, t)),
              ),
          ],
        ),
        Positioned(
          right: 22,
          bottom: 20,
          child: FloatingActionButton(
            tooltip: 'Adicionar tarefa',
            onPressed: () => showTaskEditor(context),
            backgroundColor: Brand.purple,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, size: 32),
          ),
        ),
      ],
    );
  }

  Future<void> _showFilters() async {
    final state = DuoScope.of(context);
    var owner = _owner,
        category = _category,
        difficulty = _difficulty,
        sort = _sort;
    await duoSheet<void>(
      context,
      StatefulBuilder(
        builder: (c, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeading(
              'Do seu jeito',
              subtitle: 'Encontre a próxima missão da casa.',
            ),
            DropdownButtonFormField<String>(
              initialValue: owner,
              decoration: const InputDecoration(labelText: 'Responsável'),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('A dupla toda'),
                ),
                ...state.members.map(
                  (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                ),
              ],
              onChanged: (v) => update(() => owner = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('Todos os ambientes'),
                ),
                ...TaskCategory.values.map(
                  (v) => DropdownMenuItem(value: v.name, child: Text(v.label)),
                ),
              ],
              onChanged: (v) => update(() => category = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: difficulty,
              decoration: const InputDecoration(labelText: 'Dificuldade'),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('Todas as dificuldades'),
                ),
                ...Difficulty.values.map(
                  (v) => DropdownMenuItem(value: v.name, child: Text(v.label)),
                ),
              ],
              onChanged: (v) => update(() => difficulty = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: sort,
              decoration: const InputDecoration(labelText: 'Ordenar por'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Prazo mais próximo')),
                DropdownMenuItem(value: 1, child: Text('Mais XP')),
                DropdownMenuItem(value: 2, child: Text('Nome da tarefa')),
              ],
              onChanged: (v) => update(() => sort = v!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                setState(() {
                  _owner = owner;
                  _category = category;
                  _difficulty = difficulty;
                  _sort = sort;
                });
                Navigator.pop(c);
              },
              child: const Text('Aplicar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
