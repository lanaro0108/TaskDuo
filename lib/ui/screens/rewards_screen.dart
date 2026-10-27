import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme.dart';
import '../widgets/art.dart';
import '../widgets/components.dart';
import '../widgets/editors.dart';
import '../widgets/panels.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;
  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  int _tab = 0;
  String? _periodKey;
  String _periodLabel(CompetitionResult p) {
    final last = addCalendarDays(p.end, -1);
    return '${shortDate(p.start)}/${p.start.year} a ${shortDate(last)}/${last.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = DuoScope.of(context), p = Palette.of(context);
    final wins = state.unclaimedWins;
    if (!wins.any((w) => w.key == _periodKey)) {
      _periodKey = wins.firstOrNull?.key;
    }
    final history = state.redemptions
        .where((r) => r.memberId == state.active.id)
        .toList()
        .reversed;
    final last = state.closedCompetitions.firstOrNull;
    return ListView(
      key: const PageStorageKey('rewards'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        const ScreenHeader('Recompensas'),
        AppCard(
          gradient: p.reward,
          border: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Um prêmio para quem vencer',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                '${state.active.name}: ${state.points(state.active.id)} pontos · ${state.partner.name}: ${state.points(state.partner.id)} pontos',
              ),
              const SizedBox(height: 8),
              const Text(
                'A disputa vai de segunda a domingo. Após o fechamento, quem tiver mais pontos escolhe uma recompensa. Empate não dá prêmio.',
              ),
              const SizedBox(height: 8),
              Text(
                'Próximo fechamento: ${shortDate(addCalendarDays(weekStart(state.today), 7))}, à meia-noite.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (wins.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            key: ValueKey('${state.active.id}:$_periodKey'),
            initialValue: _periodKey,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Semana que você venceu',
            ),
            items: wins
                .map(
                  (w) => DropdownMenuItem(
                    value: w.key,
                    child: Text(_periodLabel(w)),
                  ),
                )
                .toList(),
            onChanged: (key) => setState(() => _periodKey = key),
          ),
          const SizedBox(height: 10),
          const Text('Você tem direito a um prêmio pela semana selecionada.'),
        ] else
          Text(
            last == null
                ? 'A primeira disputa ainda está em andamento.'
                : last.winnerId == null
                ? 'Última disputa: empate. Não houve vencedor.'
                : 'Última disputa: ${state.member(last.winnerId!).name} venceu. ${last.winnerId == state.active.id ? 'O prêmio já foi escolhido.' : 'O prêmio pertence a esse perfil.'}',
          ),
        const SizedBox(height: 18),
        Segments(
          items: const ['Catálogo', 'Meus prêmios'],
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 18),
        if (_tab == 0) ...[
          if (state.rewards.isEmpty)
            const EmptyState(
              title: 'Qual vai ser o prêmio?',
              message: 'Criem juntos as recompensas que combinam com vocês.',
              art: 'gift',
            )
          else
            ...state.rewards.map(
              (reward) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: _periodKey == null
                      ? null
                      : () => _choose(reward, _periodKey!),
                  child: Row(
                    children: [
                      Art(reward.art, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reward.title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _periodKey == null
                                  ? 'Disponível para quem vencer'
                                  : 'Escolher como prêmio',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _periodKey == null
                            ? Icons.lock_outline_rounded
                            : Icons.chevron_right_rounded,
                        color: p.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => showRewardEditor(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Criar recompensa da dupla'),
          ),
        ] else if (history.isEmpty)
          EmptyState(
            title: 'Seu primeiro prêmio espera por você',
            message: 'Vença uma semana e escolha uma recompensa do catálogo.',
            art: 'trophy',
            action: 'Ver tarefas',
            onAction: () => widget.onNavigate(1),
          )
        else
          ...history.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  children: [
                    Art(r.art, size: 45),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            r.periodKey == null
                                ? 'Resgate anterior à disputa por pontos'
                                : 'Semana de ${shortDate(DateTime.parse(r.periodKey!))}/${DateTime.parse(r.periodKey!).year}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (r.used)
                            const Text('Recompensa usada')
                          else
                            TextButton(
                              onPressed: () => state.useRedemption(r.id),
                              child: const Text('Marcar como usada'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _choose(HouseReward reward, String periodKey) async {
    final state = DuoScope.of(context);
    var submitted = false;
    await duoSheet<void>(
      context,
      Builder(
        builder: (c) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Art(reward.art, size: 88)),
            const SizedBox(height: 16),
            SheetHeading(reward.title, subtitle: reward.description),
            const Text(
              'Você pode escolher uma recompensa por semana vencida. Confirme o prêmio combinado com sua dupla.',
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                if (submitted) return;
                submitted = true;
                final error = state.redeem(reward.id, periodKey: periodKey);
                Navigator.pop(c);
                toast(
                  context,
                  error ?? 'Prêmio escolhido! Confira em Meus prêmios.',
                );
              },
              icon: const Icon(Icons.emoji_events_outlined),
              label: const Text('Confirmar meu prêmio'),
            ),
          ],
        ),
      ),
    );
  }
}
