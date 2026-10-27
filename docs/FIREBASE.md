# Evolução do TaskDuo com Firebase

Este documento é um plano de implementação. O aplicativo atual continua local: não há Firebase configurado, login, sincronização ou validação por servidor.

## Regras que o backend deve preservar

- Uma ocorrência concluída rende 15, 25 ou 40 pontos ao responsável, conforme a dificuldade. O mesmo valor evolui o XP pessoal. Repetir a requisição não concede pontos novamente.
- A disputa vai de segunda-feira, 00:00, até a segunda seguinte, 00:00, com limite final exclusivo. A pontuação da semana reinicia sem apagar XP, histórico ou recordes.
- Somente o vencedor de uma semana encerrada escolhe um prêmio do catálogo. Cada semana admite uma única escolha. Empates e semanas sem atividade não geram prêmio. Não há compra por saldo de moedas.
- Uma sequência conta dias distintos com pelo menos uma conclusão. Várias tarefas no mesmo dia não aumentam a quantidade de dias. Ontem mantém a sequência até o fim de hoje. Recorde e conquistas permanecem após uma interrupção.
- Pontos e sequência pertencem ao responsável da tarefa, mesmo quando a outra pessoa registra a conclusão. A permissão de concluir tarefas da casa deve ser validada pelo backend.

## Identidade e fuso horário

Use Firebase Authentication para obter um UID por pessoa e mantenha a associação de exatamente dois membros à casa no servidor. Os IDs locais `ana` e `bruna` não são identidades autenticadas. Convites devem ter validade e uso único, com entrada do segundo membro validada em transação.

A casa deve ter um fuso IANA, por exemplo `America/Sao_Paulo`. Ele define os dias da sequência e as semanas da disputa para os dois aparelhos. Viajar ou alterar o fuso do celular não pode mudar a pontuação. Mudanças do fuso da casa devem valer somente a partir de uma próxima disputa, com a versão da configuração registrada no período.

Grave cada evento com `acceptedAt` em UTC, `dayKey` e `roundKey` calculados pelo servidor no fuso da casa, além de `timeZone`. Os campos de calendário ficam imutáveis após a aceitação. Use operações de calendário de uma biblioteca com suporte a IANA; não divida instantes por 24 horas nem some 86.400 segundos para avançar uma data local.

## Estrutura sugerida no Firestore

| Caminho dentro de `households/{houseId}` | Conteúdo |
| --- | --- |
| documento da casa | `memberIds`, fuso, versão das regras e início da primeira disputa |
| `members/{uid}` | Nome, avatar estável e preferências do perfil |
| `tasks/{taskId}` | Definição da tarefa, responsável e recorrência |
| `occurrences/{occurrenceId}` | Ocorrência concreta, prazo, dificuldade e conclusão |
| `completions/{occurrenceId}` | Registro imutável de pontos e datas validados pelo servidor |
| `members/{uid}/activeDays/{dayKey}` | Quantidade de conclusões aceitas naquele dia e primeira aceitação |
| `members/{uid}/stats/current` | Resumo derivado: XP, último dia ativo, sequência e recorde |
| `members/{uid}/achievements/{achievementId}` | `unlockedAt` e evento que desbloqueou a conquista |
| `rounds/{roundKey}` | Início/fim UTC, fuso, placar dos dois membros, estado e vencedor |
| `rewards/{rewardId}` | Catálogo combinado pela dupla, sem preço em moedas |
| `prizeClaims/{roundKey}` | Única escolha da semana, dono, cópia do prêmio e uso |

Use um ID determinístico por ocorrência recorrente, como série + revisão da agenda + data programada. Edições da recorrência afetam ocorrências futuras. O ID do registro de conclusão deve ser o da ocorrência; o ID do prêmio deve ser o da semana, compartilhado entre os dois perfis.

## Concluir uma tarefa com segurança

Implemente uma callable Cloud Function `completeOccurrence` com Authentication e App Check. O aplicativo envia `houseId`, `occurrenceId` e um identificador estável da operação. O cliente não escolhe pontos, vencedor, dono do prêmio ou data oficial.

Na função:

1. Verifique identidade, associação à casa, formato e tamanho dos dados e permissão sobre a ocorrência.
2. Em uma transação, leia a ocorrência, a conclusão existente, a casa, o período, o dia ativo e o resumo do responsável. Execute as leituras antes das gravações.
3. Se a ocorrência já estiver concluída, devolva o resultado existente. Dois identificadores de operação diferentes ainda devem disputar a mesma ocorrência.
4. Valide o prazo da recorrência e obtenha a dificuldade registrada na ocorrência. Calcule a pontuação no servidor e as chaves de calendário no fuso da casa.
5. Grave atomicamente a conclusão, o estado da ocorrência, o XP, o dia ativo, o placar da semana e a próxima ocorrência determinística. Atualize recorde e conquistas quando necessário.

O callback da transação pode executar várias vezes. Não envie notificações nem faça outros efeitos externos dentro dele. Para efeitos posteriores, use um registro de saída com ID determinístico e um consumidor idempotente.

## Sequência atual, recorde e conquistas

O histórico de dias ativos é a fonte de verdade. O resumo é uma projeção para leitura rápida e deve poder ser reconstruído.

- Se o último dia ativo for hoje, exiba a sequência que termina hoje.
- Se for ontem, mantenha a sequência com a mensagem de que ainda é necessário concluir uma tarefa hoje.
- Se for anterior a ontem, exiba zero para a sequência atual. Preserve o maior intervalo consecutivo já obtido.
- Ao receber outra conclusão do mesmo dia, atualize a quantidade de tarefas, sem acrescentar outro dia à sequência.
- Grave a conquista de sete dias apenas uma vez. Ela não depende de a sequência atual continuar ativa.

Não é necessário zerar todos os perfis com uma função diária: o valor atual pode ser derivado de `lastActiveDay` e da data oficial. O app ainda precisa atualizar sua apresentação na virada do dia e ao voltar ao primeiro plano. Um backend não provoca sozinho a reconstrução de uma tela sem mudanças nos documentos.

Se permitir importações ou eventos retroativos futuramente, não use apenas `streak += 1`: eventos podem chegar fora de ordem e preencher intervalos antigos. Recalcule os intervalos a partir de `activeDays`, preserve `longestStreak` e registre a política de correção aplicada.

## Fechar a semana e entregar um único prêmio

Use uma função agendada para procurar períodos cujo fim UTC já passou. Também permita ao backend finalizar um período vencido ao consultar resultados ou solicitar um prêmio. Assim, uma execução atrasada do agendador não depende do usuário manter o aplicativo aberto.

O fechamento deve ser idempotente e usar uma transação sobre o documento do período. Conclusões e fechamento precisam disputar a mesma versão desse documento: depois que o período for fechado, o placar não pode receber novas gravações. A função de conclusão deve revalidar o horário e o estado do período em cada tentativa da transação. Se o limite já passou, encaminhe a aceitação para a semana atual conforme a política offline abaixo.

No fechamento, compare o placar. Empate mantém `winnerId: null`; uma vitória registra o UID vencedor. Guarde o resultado e a versão das regras. Nunca decida o vencedor a partir do cache de um aparelho.

A callable `claimPrize` lê casa, período fechado, prêmio e `prizeClaims/{roundKey}`. Exige `request.auth.uid == winnerId`. Se já houver escolha, devolve a escolha existente, sem trocar o prêmio. Caso contrário, grava a cópia do nome/descrição/arte e o dono em uma única transação. Somente esse dono pode marcar a recompensa como usada. Edições posteriores do catálogo não alteram prêmios entregues.

## Uso offline: explicitar o que está pendente

O cache offline do Firestore permite consultar dados e enfileirar gravações suportadas. Ele não transforma uma callable em operação offline; transações de cliente também falham sem conexão.

Use uma fila local durável, preferencialmente em armazenamento estruturado, para pedidos de conclusão. Mostre `Pendente de sincronização`, e diferencie estimativas locais de pontos confirmados. Reenvie o mesmo identificador de operação ao reconectar. Não libere prêmio com uma vitória ainda pendente.

Política inicial recomendada: a conclusão entra no dia e na semana em que o servidor a aceitar. Uma tarefa feita offline no domingo e enviada na segunda soma na segunda; o horário informado pelo aparelho não comprova quando ela foi feita. Explique essa regra antes da conclusão offline. Preservar retroativamente o domingo exige outra política explícita, janela de tolerância e fechamento adiado; não conceda essa exceção silenciosamente.

## Regras de acesso e validação

- Um usuário só lê dados das casas de que participa.
- Bloqueie gravações diretas de clientes em conclusões, placares, vencedores, XP, sequências, conquistas e prêmios concedidos. Essas operações passam pelas funções.
- Valide campos permitidos, tamanho dos textos, IDs e limites nas edições autorizadas de perfil, tarefas e catálogo. Não permita ao cliente editar a lista de membros ou o fuso de uma disputa em andamento.
- A Admin SDK ignora as Security Rules. As funções precisam validar autorização e entrada por conta própria. App Check complementa a autenticação; não a substitui.
- Não salve credenciais administrativas no Flutter. Revise índices e limites de leitura, use emuladores durante o desenvolvimento e configure orçamento antes de colocar funções/agendamento em produção.

## Migração e implantação em etapas

1. Mantenha exportação e uma cópia recuperável dos dados locais antes da migração para contas reais. A versão local 2 já remove exemplos, mantém ações reais e arquiva resgates do sistema antigo.
2. Adicione Auth e criação/convite da casa. Faça a dupla confirmar qual perfil local corresponde a cada conta.
3. Introduza um repositório sincronizado e leituras por `snapshots`, incluindo estados carregando, offline, pendente e erro.
4. Implemente e teste as funções e regras nos emuladores. Pontos locais antigos não se tornam pontuação oficial apenas porque foram enviados: importe-os como histórico identificado ou comece a primeira disputa oficial do zero.
5. Ative conclusão, sequência, fechamento e escolha de prêmio no backend. Depois acrescente FCM para lembretes, com consentimento e controle por perfil.

Teste requisições duplicadas, duas conclusões simultâneas em aparelhos diferentes, duas escolhas de prêmio concorrentes, perda de conexão após uma transação, tentativa de escolher pelo perfil perdedor, empate, limite domingo/segunda, mudança de mês/ano, dias de 23/25 horas, relógio adulterado, evento offline atrasado, agendador repetido/atrasado e usuário de outra casa.

## Documentação oficial

- [Transações e gravações em lote](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [Persistência e acesso offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [Callable Cloud Functions](https://firebase.google.com/docs/functions/callable)
- [Funções agendadas](https://firebase.google.com/docs/functions/schedule-functions)
- [Security Rules e Authentication](https://firebase.google.com/docs/firestore/security/rules-conditions)
- [App Check em callable functions](https://firebase.google.com/docs/app-check/cloud-functions)
- [Testes com o Emulator Suite](https://firebase.google.com/docs/emulator-suite)
