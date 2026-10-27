# Arquitetura

A estrutura usa `ChangeNotifier` e `InheritedNotifier`, suficientes para uma aplicação pequena com um estado de casa compartilhado.

`DuoState` recebe `LocalStore` e um relógio injetável. Ele controla as transações de tarefas e recompensas, os pontos derivados do histórico, os períodos, as conquistas e as preferências. As telas chamam essas ações e apresentam os resultados. Filtros e seleção de abas ficam no estado de cada tela.

`PreferencesStore` implementa o armazenamento com SharedPreferences no Android e no navegador. Os dados são serializados com versão de formato 2, com leitura e migração da versão 1. Gravações entram numa fila para preservar a ordem mesmo quando várias ações acontecem rapidamente. O estado inclui um contador de IDs persistido. Leituras inválidas preservam o conteúdo anterior; uma ação explícita de reiniciar a jornada permite substituir os dados. Falhas de gravação mantêm a sessão em memória e apresentam uma nova tentativa.

Pontos da disputa vêm das conclusões do período; XP continua representando a evolução pessoal. Resultados elegíveis são apenas semanas encerradas após o início da disputa. A escolha de prêmio guarda `periodKey`, e o domínio bloqueia uma segunda escolha para a mesma semana e o uso pelo outro perfil. Resgates antigos têm `periodKey: null` e permanecem como arquivo, sem saldo de moedas ativo.

A sequência atual e o recorde são derivados dos dias distintos no histórico. Comparações usam ordinais de calendário construídos em UTC a partir da data local, evitando dias de 23/25 horas. Recorrências e limites de período avançam pelo construtor de calendário. A conquista de sete dias utiliza o maior intervalo histórico, independente da sequência atual. O shell cancela seu timer ao sair do primeiro plano e atualiza a data ao retomar e à meia-noite.

`HouseholdSnapshot` valida a estrutura completa antes de aplicá-la: membros únicos, referências, IDs, valores, preferências, arte, consistência das conclusões e unicidade das semanas premiadas. Histórico de tarefas removidas continua válido. Uma leitura inválida preserva o último estado válido e bloqueia a sobrescrita dos bytes salvos.

### Migração local 1 → 2

O armazenamento mantém a mesma chave e a interface `LocalStore`. A versão 1 é validada antes da migração. Removem-se tarefas `starter-*` e os cinco prêmios de exemplo identificados. Quando `sampleData` está ativo, retiram-se conclusões `example-ana-*`/`example-bruna-*` e os totais base fictícios. Perfis, IDs dos quatro avatares existentes, itens personalizados, preferências, conclusões reais e resgates históricos permanecem. O início da disputa é a semana da migração, sem distribuir novos prêmios por semanas antigas. A próxima gravação bem-sucedida serializa a versão 2; até lá, o original permanece intacto. A migração é idempotente; uma versão futura desconhecida é rejeitada.

Os campos legados `coins`, `cost` e `weeklyBonuses` permanecem legíveis para preservar o contrato e o arquivo anterior. Novas conclusões gravam `coins: 0`; novos prêmios não têm preço e escolhas de vencedor gravam `cost: 0`. Não são usados para calcular saldo ou elegibilidade. Não houve migração de usuários para contas remotas.

Componentes comuns ficam em `ui/widgets`. `Palette` e `ThemeData` centralizam os dois temas. A aplicação usa recursos locais e o build web inclui CanvasKit para não depender de um CDN em tempo de execução.

## Evolução para Firebase

O plano detalhado está em [FIREBASE.md](FIREBASE.md): Auth, fuso IANA por casa, eventos idempotentes, dias ativos, resultados fechados no servidor, escolha única do vencedor e política offline explícita. A implementação atual usa relógio e fuso do aparelho; ainda não protege contra adulteração do relógio nem oferece concorrência entre celulares.

SharedPreferences continua adequado ao volume local pequeno. Antes de ampliar o histórico e adicionar uma fila offline durável, introduza armazenamento estruturado e backup com política de migração.
