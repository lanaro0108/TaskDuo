# Produto

TaskDuo transforma as tarefas domésticas de duas pessoas em colaboração, progresso e recompensas combinadas. A primeira versão é local e utiliza Ana e Bruna como nomes de exemplo editáveis.

## Regras implementadas

- Uma tarefa tem título, descrição, ambiente, dificuldade, responsável, data e frequência.
- Dificuldade leve rende 15 pontos; média, 25; caprichada, 40. O mesmo valor evolui o XP pessoal, que continua determinando o nível. Não há compra de recompensas por moedas.
- Os pontos pertencem ao responsável da tarefa. A conclusão de uma mesma ocorrência só pode creditar uma vez.
- Tarefas recorrentes geram uma próxima ocorrência após o dia atual ou o prazo futuro. A próxima ocorrência recorrente fica indisponível até a data programada.
- Cada 500 XP eleva um nível. A barra exibe o progresso dentro do nível atual.
- A sequência conta dias de calendário distintos com tarefas concluídas pelo responsável; várias conclusões no mesmo dia contam como um dia. A conclusão de ontem mantém a sequência até o fim do dia atual. O recorde vem do histórico e a conquista de sete dias permanece desbloqueada após uma interrupção.
- A semana começa na segunda-feira. O desafio de dez tarefas da dupla registra uma conquista coletiva, sem bônus financeiro.
- O ranking usa o histórico do período selecionado. Os pontos anteriores aos exemplos recentes participam apenas do total geral.
- Somente o maior placar de uma semana encerrada libera um prêmio ao vencedor. Empate não libera prêmio. Cada semana pode ter uma única escolha, mesmo após reabrir o app. O vencedor pode escolher posteriormente entre os prêmios do catálogo; o histórico guarda a cópia do prêmio e a semana vencida.
- Cada pessoa só marca suas próprias recompensas como usadas. Os prêmios são acordos entre a dupla, sem compra ou pagamento.
- Excluir uma tarefa não remove pontos que já foram conquistados.
- Preferências, edições e histórico são salvos no dispositivo. Falhas de gravação aparecem na interface com opção de tentar novamente. Dados ilegíveis não são substituídos silenciosamente.

Novas instalações não têm tarefas, prêmios ou histórico de exemplo. A migração remove os exemplos identificados da versão anterior, preservando itens personalizados, ações reais e resgates antigos como histórico. Os dez avatares mantêm os quatro IDs anteriores e acrescentam opções femininas e masculinas de cabelo liso e cacheado.

A lista de hoje, a sequência e os resultados são atualizados ao retomar o app e na virada do dia. O calendário local usa o fuso do aparelho; a evolução para um fuso único da casa validado no servidor está em [Firebase](FIREBASE.md).

## Telas

Início resume o dia e o desafio. Tarefas reúne execução e organização. Ranking compara períodos e conquistas. Recompensas apresenta o catálogo da dupla e os prêmios das semanas vencidas. Perfil concentra identidade, evolução, tema e gerenciamento da dupla.

## Escopo seguinte

Autenticação, convite para a casa, sincronização entre dois celulares, resolução de conflitos, aprovação remota, notificações do sistema e regras de segurança ainda precisam ser implementados. A versão local não solicita credenciais para essas funções futuras.
