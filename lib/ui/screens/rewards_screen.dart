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
  @override
  Widget build(BuildContext context) {
    final state = DuoScope.of(context);
    final p = Palette.of(context);
    final balance = state.coins(state.active.id);
    final available = state.rewards
        .where((r) => _tab != 1 || r.cost <= balance)
        .toList();
    final history = state.redemptions
        .where((r) => r.memberId == state.active.id)
        .toList()
        .reversed
        .toList();
    final featured = state.rewards.firstOrNull;
    return ListView(
      key: const PageStorageKey('rewards'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        ScreenHeader('Recompensas', trailing: CoinLabel(balance, size: 17)),
        if (featured != null) ...[
          AppCard(
            gradient: p.reward,
            border: false,
            onTap: () => _redeem(featured),
            padding: const EdgeInsets.fromLTRB(18, 20, 12, 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESTAQUE DA SEMANA',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w900,
                          color: p.dark
                              ? const Color(0xffc1a4ff)
                              : const Color(0xff8260d1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        featured.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        featured.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      CoinLabel(featured.cost, suffix: ' moedas', size: 12),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Art(featured.art, size: 90),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Segments(
          items: const ['Todas', 'Disponíveis', 'Resgatadas'],
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 18),
        if (_tab == 2) ...[
          if (history.isEmpty)
            EmptyState(
              title: 'Seus pequenos prazeres moram aqui',
              message: 'Escolha uma recompensa e troque suas moedas por um momento especial.',
              art: 'gift',
              action: 'Explorar recompensas',
              onAction: () => setState(() => _tab = 0),
            )
          else
            ...history.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: AppCard(
                  child: Row(
                    children: [
                      Art(r.art, size: 45),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${shortDate(r.at)} · ${r.cost} moedas · ${r.used ? 'Usada' : 'Pronta para usar'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (!r.used)
                              Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: OutlinedButton(
                                  onPressed: () {
                                    state.useRedemption(r.id);
                                    toast(
                                      context,
                                      'Aproveite! Recompensa marcada como usada.',
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 34),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                    ),
                                  ),
                                  child: const Text(
                                    'Marcar como usada',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (r.used)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 23,
                          color: Brand.mint,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ] else ...[
          if (available.isEmpty)
            EmptyState(
              title: 'Seu próximo prêmio está chegando',
              message: 'Conclua mais algumas tarefas para juntar moedas.',
              art: 'coin',
              action: 'Ver minhas tarefas',
              onAction: () => widget.onNavigate(1),
            )
          else
            ...available.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: AppCard(
                  onTap: () => _redeem(r),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: p.tint.withValues(alpha: .7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Art(r.art, size: 48),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            CoinLabel(r.cost, suffix: ' moedas', size: 11),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        r.cost > balance
                            ? Icons.lock_outline_rounded
                            : Icons.chevron_right_rounded,
                        size: 20,
                        color: p.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 9),
        OutlinedButton.icon(
          onPressed: () => showRewardEditor(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Criar recompensa da dupla'),
        ),
        const SizedBox(height: 14),
        Text(
          'Prêmios simples. Momentos que valem muito.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _redeem(HouseReward reward) async {
    final state = DuoScope.of(context);
    final balance = state.coins(state.active.id);
    final enough = balance >= reward.cost;
    var submitted = false;
    await duoSheet<void>(
      context,
      Builder(
        builder: (c) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Art(reward.art, size: 100)),
            const SizedBox(height: 14),
            SheetHeading(reward.title, subtitle: reward.description),
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text('Seu saldo'), CoinLabel(balance)],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Custo da recompensa'),
                      CoinLabel(reward.cost),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Divider(color: Palette.of(c).line),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        enough ? 'Depois do resgate' : 'Ainda faltam',
                        style: Theme.of(c).textTheme.titleSmall,
                      ),
                      CoinLabel((balance - reward.cost).abs()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (!enough)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Mais algumas missões e esse prêmio é seu!',
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton.icon(
              onPressed: enough
                  ? () {
                      if (submitted) return;
                      submitted = true;
                      final error = state.redeem(reward.id);
                      Navigator.pop(c);
                      toast(
                        context,
                        error ??
                            'Recompensa resgatada! Veja na aba Resgatadas.',
                      );
                    }
                  : null,
              icon: Icon(
                enough ? Icons.redeem_rounded : Icons.lock_outline_rounded,
              ),
              label: Text(
                enough
                    ? 'Resgatar por ${reward.cost} moedas'
                    : 'Saldo insuficiente',
              ),
            ),
            const SizedBox(height: 13),
            const Text(
              'Combine o momento de aproveitar com a sua dupla.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
