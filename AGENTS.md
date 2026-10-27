# Trabalhar no TaskDuo

- O produto é Flutter, com foco em Android e suporte web para revisão da interface. Leia `docs/PRODUCT.md` e `docs/DESIGN_SYSTEM.md` antes de alterar telas.
- A nova implementação foi autorizada pelo usuário porque o repositório original tinha apenas README. O código em `lib/` é agora a base a evoluir.
- Preserve as cinco abas, a identidade lavanda/azul, os dois temas e as funcionalidades existentes. Faça mudanças incrementais e reutilize os componentes.
- Use o checkout existente. Tarefas de nuvem já são isoladas; não crie worktrees sem pedido explícito.
- Mantenha a lógica de XP, moedas, recorrências e resgates em `domain/duo_state.dart`, não em widgets. Preserve o contrato do armazenamento e planeje migrações antes de alterar o formato persistido.
- Os dados iniciais são exemplos. Métricas novas devem derivar de ações e histórico; não simule integração, aprovação, login ou notificações remotas.
- Firebase é uma etapa posterior. Não inclua credenciais ou afirme que há sincronização entre aparelhos.
- Preserve licenças de fontes e ilustrações. Recursos visuais devem funcionar sem carregamento de imagens remoto.
- Execute `flutter analyze` e os testes pertinentes. Valide alterações visuais nas larguras 320 e 430, nos dois temas; confirme os builds afetados. Nunca descreva um teste não executado como aprovado.
- No ambiente de nuvem, use `source /workspace/.taskduo-tools/env.sh`. SDKs e caches ficam fora do checkout. Veja o README para execução local.
