# Arquitetura

A estrutura usa `ChangeNotifier` e `InheritedNotifier`, suficientes para uma aplicação pequena com um estado de casa compartilhado.

`DuoState` recebe `LocalStore` e um relógio injetável. Ele controla as transações de tarefas e recompensas, os saldos derivados do histórico, os períodos, as conquistas e as preferências. As telas chamam essas ações e apresentam os resultados. Filtros e seleção de abas ficam no estado de cada tela.

`PreferencesStore` implementa o armazenamento com SharedPreferences no Android e no navegador. Os dados são serializados com versão de formato 1. Gravações entram numa fila para preservar a ordem mesmo quando várias ações acontecem rapidamente. O estado inclui um contador de IDs persistido. Leituras inválidas preservam o conteúdo anterior; uma ação explícita de reiniciar a jornada permite substituir os dados. Falhas de gravação mantêm a sessão em memória e apresentam uma nova tentativa.

Moedas são calculadas a partir de conclusões e bônus, descontando resgates. XP vem das conclusões e dos pontos históricos de exemplo. Histórico de conclusão permanece após exclusão da tarefa. A próxima recorrência é criada somente na primeira conclusão de uma ocorrência, e datas futuras recorrentes não podem ser concluídas antecipadamente.

Componentes comuns ficam em `ui/widgets`. `Palette` e `ThemeData` centralizam os dois temas. A aplicação usa recursos locais e o build web inclui CanvasKit para não depender de um CDN em tempo de execução.

## Evolução para Firebase

Introduzir um repositório de casa sincronizado, autenticação e IDs de usuário reais. Migrar os exemplos de forma explícita; não associar os perfis locais a contas sem confirmação. Operações de XP, moedas e resgates deverão ser transações idempotentes no backend com regras por membro da casa. Conflitos, convites e validação de permissões exigem testes próprios antes da sincronização.

SharedPreferences é adequado para esta etapa de dados pequenos. Histórico extenso, backup e sincronização pedem armazenamento estruturado e uma política de migração.
