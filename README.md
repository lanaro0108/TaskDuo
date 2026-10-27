# TaskDuo

Juntos por uma casa mais organizada. Aplicativo Flutter para organizar os cuidados da casa em dupla, com a identidade lavanda e azul da referência aprovada.

## O que funciona

- **Início:** nível, XP, moedas, sequência de dias, tarefas de hoje, desafio semanal e atividade recente.
- **Tarefas:** criar, editar, excluir, concluir, atribuir à dupla, buscar sem acentos, filtrar e ordenar; recorrência diária e semanal.
- **Ranking:** semana, mês e geral; comparação da dupla, desempenho por categoria e oito conquistas com progresso.
- **Recompensas:** catálogo, criação de prêmios, confirmação com saldo antes/depois, resgates e marcação de uso.
- **Perfil:** editar nomes e avatares, alternar entre os dois perfis, evolução de XP, preferências e temas claro, escuro e do sistema.
- **Persistência local:** tarefas, histórico, moedas, resgates, perfis e preferências sobrevivem ao fechamento do aplicativo.

Os dados iniciais são exemplos para reproduzir a referência. Use **Perfil → Começar minha jornada** para zerar o histórico, XP, moedas e resgates. O diálogo explica o que será mantido antes de confirmar.

Esta etapa usa dois perfis no mesmo aparelho. Contas, sincronização entre celulares, aprovação remota de tarefas e notificações do sistema pertencem à próxima etapa com Firebase. A opção de notificações atual controla o indicador de atividade dentro do app.

## Executar

Ferramentas usadas: **Flutter 3.47.8**, Dart 3.13.7, JDK 21 e Android SDK 36.

```sh
flutter pub get --enforce-lockfile
flutter run
```

No ambiente de nuvem preparado nesta conversa, ative as ferramentas antes:

```sh
source /workspace/.taskduo-tools/env.sh
cd /workspace/TaskDuo
```

Para desenvolver com um dispositivo ou emulador Android, confira `flutter devices` e selecione o dispositivo com `flutter run -d <id>`.

## Validar e compilar

```sh
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
flutter build apk --debug --target-platform=android-arm64
```

O build web inclui os recursos de renderização localmente. Para servir esse build, use `python3 -m http.server 7357 --directory build/web`. O APK de desenvolvimento é produzido em `build/app/outputs/flutter-apk/app-debug.apk`; uma distribuição pública exige chave de assinatura própria.

## Organização

```text
lib/
  app.dart                  # Temas, navegação e adaptação mobile/desktop
  data/local_store.dart     # Armazenamento local substituível
  domain/models.dart        # Entidades e datas
  domain/duo_state.dart      # Regras, estado e persistência
  ui/theme.dart             # Tokens e ThemeData
  ui/screens/               # As cinco telas
  ui/widgets/               # Cards, ilustrações, formulários e painéis
test/                       # Regras de negócio e fluxos de interface
docs/                       # Produto, design, arquitetura e próximos passos
```

Veja [produto](docs/PRODUCT.md), [design system](docs/DESIGN_SYSTEM.md), [arquitetura](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md) e [resultados de validação](docs/VALIDATION.md).

## Créditos

Ilustrações 3D: [Microsoft Fluent Emoji](https://github.com/microsoft/fluentui-emoji), licença MIT preservada em `assets/art/LICENSE.txt`. Fonte Nunito: [Google Fonts](https://github.com/google/fonts/tree/main/ofl/nunito), licença OFL em `assets/fonts/OFL.txt`. Mascote, marca e avatares desenhados no aplicativo.
