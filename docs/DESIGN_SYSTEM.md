# Design system

A referência aprovada mostra um aplicativo Android acolhedor, com cinco abas, cards arredondados e gamificação discreta. A implementação traduz essa referência em componentes Flutter reutilizáveis.

| Token | Claro | Escuro |
| --- | --- | --- |
| Fundo | `#F8F9FF` | `#101725` |
| Superfície | `#FFFFFF` | `#192338` |
| Superfície elevada | `#F0EFFC` | `#202B43` |
| Texto principal | `#171944` | `#F6F5FF` |
| Texto secundário | `#68708E` | `#A6AFCA` |
| Bordas | `#EEEDF9` | `#2B3550` |

Marca: lavanda `#7160FF`, azul `#5077FF`, lilás `#AF8AF8`, sucesso `#43CBA7`, destaques `#FFBD30`. Tokens e gradientes estão em `lib/ui/theme.dart`.

- Fonte Nunito incluída no pacote, com títulos em peso 800/900 e textos regulares em 600.
- Espaçamento lateral mobile: 20 px. Cards: raio 20 px e padding de 13–18 px. Campos e botões: raio 15–16 px.
- Ícones e ilustrações têm apoio textual. Alvos interativos têm pelo menos 48 × 48 dp; conclusão e edição usam tooltips e semântica; navegação indica a aba ativa.
- Gradientes lavanda/azul para XP e desafios; lavanda/rosa para o destaque de recompensas. No escuro, superfícies marinho e contraste entre cards substituem sombras fortes.
- Mascote e avatares são vetoriais; os dez retratos incluem opções femininas e masculinas, lisas e cacheadas, com seleção identificada por texto e semântica; ilustrações Fluent Emoji são locais. Não há dependência de imagens remotas.
- Tema pode ser claro, escuro ou seguir o sistema. A preferência é persistida. Há opções de animação, sons e vibração.
- No mobile a navegação fica embaixo. A partir de 900 px, uma barra lateral substitui a navegação inferior. Conteúdo limitado a 680 px mantém a leitura confortável.
- Listas, formulários e painéis são roláveis. Estados vazios, buscas sem resultado, indisponibilidade de prêmio antes do fechamento e erros de armazenamento têm mensagens e ações específicas.

A área de recompensas explica o fechamento semanal, empates e a escolha exclusiva pelo vencedor. O formulário de prêmio não solicita preço ou saldo. O Perfil apresenta a sequência atual, o recorde e a regra de um dia por data com tarefas concluídas.

Capturas históricas da versão anterior ficam em `docs/screenshots/` e servem para revisão, sem substituir validação funcional.
