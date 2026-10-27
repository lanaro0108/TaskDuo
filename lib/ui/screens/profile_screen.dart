import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/art.dart';
import '../widgets/components.dart';
import '../widgets/editors.dart';
import '../widgets/panels.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = DuoScope.of(context);
    final p = Palette.of(context);
    final member = state.active;
    final achievements = state.achievements(member.id);
    final themeName = switch (state.themeMode) {
      ThemeMode.light => 'Claro',
      ThemeMode.dark => 'Escuro',
      ThemeMode.system => 'Sistema',
    };
    return ListView(
      key: const PageStorageKey('profile'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        ScreenHeader(
          'Perfil',
          trailing: IconButton(
            tooltip: 'Configurações da casa',
            onPressed: () => _settings(context),
            icon: Icon(Icons.settings_outlined, size: 23, color: p.ink),
          ),
        ),
        Center(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Avatar(member, size: 108, ring: true),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: SizedBox.square(
                      dimension: 33,
                      child: IconButton.filled(
                        tooltip: 'Editar meu perfil',
                        onPressed: () => showMemberEditor(context, member),
                        style: IconButton.styleFrom(
                          backgroundColor: p.surface,
                          foregroundColor: Brand.purple,
                          padding: EdgeInsets.zero,
                          side: BorderSide(color: p.line),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                member.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Art('trophy', size: 16),
                  const SizedBox(width: 5),
                  Text(
                    'Guardiã da Casa',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: p.ink),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppCard(
          gradient: p.hero,
          border: false,
          padding: const EdgeInsets.all(17),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Brand.purple,
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Nível ${state.level(member.id)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  Text(
                    '${state.xp(member.id) % 500} / 500 XP',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              ProgressLine((state.xp(member.id) % 500) / 500, height: 10),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: StatCard(
                art: 'coin',
                value: '${state.coins(member.id)}',
                label: 'Moedas',
                compact: true,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: StatCard(
                art: 'bubble',
                value: '${state.completedCount(member.id)}',
                label: 'Tarefas',
                compact: true,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: StatCard(
                art: 'fire',
                value: '${state.streak(member.id)}',
                label: 'Streak',
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ProfileRow(
                icon: Icons.insights_rounded,
                title: 'Minha evolução',
                onTap: () => showEvolution(context),
              ),
              Divider(height: 1, indent: 17, endIndent: 17, color: p.line),
              _ProfileRow(
                icon: Icons.workspace_premium_outlined,
                title: 'Conquistas',
                value:
                    '${achievements.where((a) => a.unlocked).length}/${achievements.length}',
                onTap: () => showAchievements(context),
              ),
            ],
          ),
        ),
        const SectionTitle('Preferências'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ProfileRow(
                icon: Icons.dark_mode_outlined,
                title: 'Tema do app',
                value: themeName,
                onTap: () => showThemePicker(context),
              ),
              Divider(height: 1, indent: 17, endIndent: 17, color: p.line),
              _ProfileRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notificações no app',
                trailing: _Toggle(
                  value: state.notifications,
                  onChanged: state.setNotifications,
                ),
              ),
              _ProfileRow(
                icon: Icons.volume_up_outlined,
                title: 'Sons e vibração',
                trailing: _Toggle(
                  value: state.sounds,
                  onChanged: state.setSounds,
                ),
              ),
              _ProfileRow(
                icon: Icons.auto_awesome_outlined,
                title: 'Animações',
                trailing: _Toggle(
                  value: state.animations,
                  onChanged: state.setAnimations,
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('A nossa casa'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ProfileRow(
                icon: Icons.people_outline_rounded,
                title: 'Gerenciar dupla',
                value: state.partner.name,
                onTap: () => showDuo(context),
              ),
              Divider(height: 1, indent: 17, endIndent: 17, color: p.line),
              _ProfileRow(
                icon: Icons.info_outline_rounded,
                title: 'Sobre o TaskDuo',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'TaskDuo',
                  applicationVersion: '0.1.0',
                  applicationIcon: const BrandMark(size: 50),
                  children: [
                    const Text(
                      'Juntos por uma casa mais organizada.\n\nEsta versão salva os dados neste aparelho. A sincronização entre celulares e o Firebase ficam para a próxima etapa.\n\nIlustrações: Microsoft Fluent Emoji (MIT). Fonte: Nunito (OFL).',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (state.sampleData)
          AppCard(
            color: p.tint.withValues(alpha: .6),
            border: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Um começo para se inspirar',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Os pontos e o histórico iniciais são exemplos. Quando quiser, comece a jornada da sua dupla do zero.',
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _fresh(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text(
                    'Começar minha jornada',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_rounded, size: 15, color: Brand.lilac),
            const SizedBox(width: 7),
            Text(
              'Juntos por uma casa mais organizada',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'TaskDuo · salvo neste aparelho',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  Future<void> _fresh(BuildContext context) async {
    final state = DuoScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Uma nova jornada?'),
        content: const Text(
          'O histórico de tarefas, XP, moedas e resgates será zerado. Seus nomes, preferências, tarefas pendentes e recompensas serão mantidos. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Começar do zero'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      state.startFresh();
      if (context.mounted) {
        toast(context, 'Sua jornada começou. Vamos cuidar da casa juntos!');
      }
    }
  }

  Future<void> _settings(BuildContext context) => duoSheet<void>(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHeading('Sua casa, suas regras'),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Editar meu perfil'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(context);
            showMemberEditor(context, DuoScope.of(context).active);
          },
        ),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Alterar tema'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(context);
            showThemePicker(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.people_outline_rounded),
          title: const Text('Gerenciar dupla'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(context);
            showDuo(context);
          },
        ),
      ],
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: Palette.of(context).dark
                    ? const Color(0xffb2a8ff)
                    : Brand.purple,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontSize: 12),
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    value!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 19,
                  color: Palette.of(context).muted,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Transform.scale(
    scale: .78,
    alignment: Alignment.centerRight,
    child: Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: Brand.purple,
      activeThumbColor: Colors.white,
      inactiveThumbColor: Palette.of(context).muted,
      inactiveTrackColor: Palette.of(context).raised,
      trackOutlineColor: WidgetStatePropertyAll(Palette.of(context).track),
    ),
  );
}
