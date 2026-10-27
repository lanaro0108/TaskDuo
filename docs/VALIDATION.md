# Validação da revisão de pontos e recompensas

Verificações executadas em 27/10/2026, com Flutter 3.47.8 e Dart 3.13.7, reutilizando as dependências instaladas (`--no-pub`).

| Verificação | Resultado |
| --- | --- |
| Formatação de `lib` e `test` | Concluída |
| `flutter analyze --no-pub` | Nenhum problema encontrado |
| `flutter test --no-pub` | 38 testes passaram |
| `TZ=America/New_York flutter test --no-pub test/calendar_test.dart` | 3 testes passaram, incluindo início e fim do horário de verão |
| `flutter build web --release --no-web-resources-cdn --no-pub` | Compilação concluída |
| `flutter build apk --debug --target-platform=android-arm64 --no-pub` | Compilação concluída |
| Chromium em 320 e 430 px, claro e escuro | Cinco telas, criação de tarefa/prêmio, escolha de avatar e persistência após recarregar; sem erros de página |

## Cobertura funcional

Os testes de domínio cobrem primeira criação de recompensa com catálogo vazio, tarefas sem duplicação de pontos, recorrência bloqueada no futuro, fechamento domingo/segunda, empate sem prêmio, tentativa pelo perfil perdedor, uma escolha por semana, escolha de vitórias antigas e uso exclusivo pelo dono. O histórico e o XP permanecem após reiniciar a pontuação semanal.

A sequência usa dias distintos, conserva ontem até o fim de hoje, mantém recorde e conquista após uma interrupção e sobrevive à exclusão da tarefa concluída e ao recarregamento. Os testes incluem virada de mês/ano e dias com 23/25 horas em `America/New_York`.

A persistência é testada com migração 1 → 2, remoção de exemplos, preservação de itens personalizados e ações reais, arquivo dos resgates antigos, gravações em fila, falha/repetição de gravação e rejeição de dados inválidos sem sobrescrever o original. Casos inválidos incluem membros/IDs duplicados, responsável inexistente, pontos negativos, avatar/arte desconhecidos, história inconsistente, preferências com tipo incorreto e versão/data de competição inválida.

Os widgets exercitam criação/busca/conclusão, primeira recompensa sem preço, escolha/uso de prêmio pelo vencedor, os dez avatares com persistência de um masculino cacheado, atualização ao retomar e à meia-noite, as cinco telas em 320/430 px e nos dois temas, texto em 200%, alvos Android de no mínimo 48 × 48 dp e navegação desktop.

As capturas antigas em `docs/screenshots` documentam a versão anterior, com dados de exemplo e moedas; não representam a interface atual. Capturas de conferência desta revisão ficam no diretório temporário de trabalho.

## Limites

- O APK debug foi compilado; não foi executado em um aparelho ou emulador Android nesta revisão.
- O build release e a assinatura de distribuição não foram revalidados. A configuração existente de release usa chave de desenvolvimento.
- O app continua local. A validação no servidor, proteção contra relógio adulterado, fuso único da casa e concorrência entre celulares dependem da implementação futura descrita em [FIREBASE.md](FIREBASE.md).
- Não foram configurados Firebase, credenciais ou recursos remotos; o guia descreve arquitetura, política offline, etapas e testes recomendados.
