# Validação desta entrega

Verificações executadas no ambiente de desenvolvimento com Flutter 3.47.8 e Dart 3.13.7.

| Verificação | Resultado |
| --- | --- |
| Instalação reutilizável + `flutter pub get --enforce-lockfile` | Concluída com código zero |
| `dart format --output=none --set-exit-if-changed lib test` | Sem diferenças |
| `flutter analyze` | Nenhum problema encontrado |
| `flutter test` | 15 testes passaram: 10 de domínio e 5 de interface |
| `flutter build web --release --no-web-resources-cdn` | Compilação concluída |
| `flutter build apk --debug --target-platform=android-arm64` | Compilação concluída |
| `flutter build apk --release --target-platform=android-arm64 --no-pub` | Compilação concluída; aproximadamente 20 MB |
| `apksigner verify --verbose` | Assinaturas dos APKs verificadas |
| Metadados do APK final | TaskDuo 0.1.0, arm64-v8a, Android API mínima 24, alvo 36 |

## Regras e interface

Os testes exercitam conclusão sem crédito duplicado, rejeição de edição desatualizada de tarefa já concluída, recorrência futura, saldo insuficiente, isolamento de saldos e resgates entre perfis, persistência de várias alterações em sequência, bônus semanal único, sequência de dias, períodos do ranking, edição/exclusão, validação de dados e falhas de armazenamento.

Os testes de widgets percorrem conclusão na Home, criação/busca/conclusão, resgate e uso de recompensas, troca de tema, as cinco abas na largura de 320 px e navegação desktop em 1440 px.

No Chromium, com locale pt-BR e fuso America/Sao_Paulo, a aplicação foi executada de fato e verificada em 430 × 932 px. A revisão percorreu as cinco telas em claro e escuro, confirmou o tema e uma conclusão após recarregar a página, concluiu uma tarefa com a página sem conexão e resgatou uma recompensa. Essa execução não gerou erros de página, falhas de requisição nem requisições para recursos externos. A ação offline foi testada depois do carregamento; isso não afirma que um navegador sem cache abre a aplicação sem conexão.

Também foram geradas capturas desktop em 1440 × 1000 px. Veja [as dez telas](screenshots/overview.png) e os demais arquivos em `screenshots/`.

## Limites da validação

- O APK foi compilado e sua assinatura foi verificada. A execução em um celular ou emulador Android ainda precisa ser conferida; não há dispositivo Android conectado neste ambiente.
- O APK em modo release desta etapa usa a chave de desenvolvimento. Distribuição pública exige configuração de assinatura própria.
- Os perfis e dados são locais. Firebase, autenticação, sincronização e notificações do sistema pertencem à próxima etapa.
- O workflow de GitHub Actions foi criado; sua execução no GitHub não foi realizada nesta entrega.
- Scripts e instruções do ambiente foram salvos no rascunho. Publicação e restauração em uma nova tarefa são etapas separadas, ainda não verificadas.
