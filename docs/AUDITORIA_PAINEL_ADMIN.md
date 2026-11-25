# Auditoria estática do painel administrativo

## Escopo
Revisão das migrations 0004, 0005, 0008, 0010, 0011 e do componente src/modules/admin/Admin.jsx. Esta é análise estática; nenhuma ação em banco real.

## Controles identificados
- RPCs administrativas consultam `is_app_admin()` antes de listar/revisar saques, usuários, missões e indicações (conforme migrations/componentes examinados).
- `admin_review_withdrawal` bloqueia a linha do pedido com `FOR UPDATE`, recusa pedidos já revisados e, na rejeição, estorna pontos e registra reversal na mesma função.
- Versão 0008 adiciona validação de autenticação, decisão, ID, nota limitada, checagem de perfil e atualização condicional do status pending.
- Gestão de usuário impede admin de desativar seu próprio perfil.
- Auditoria de saldo apenas lista divergências, sem corrigir automaticamente.
- Admin no front-end usa RPC e apresenta aprovação de saque como processo manual, não como pagamento PIX automático.

## Achados / riscos a verificar
1. `is_app_admin()` varia entre versões: migration 0004 verifica tabela de admins; 0006 modifica para exigir perfil ativo. A efetividade depende da sequência completa de migrations.
2. Migration 0005 adiciona `is_active` e funções de listagem/bloqueio, mas o front-end declara que o enforcement de login depende do backend; não considerar bloqueio de login comprovado apenas por desativar perfil.
3. O componente Admin.jsx não implementa uma tela evidente para concessão/remoção de administradores; bootstrap é descrito como manual. Verificar processo de provisionamento e proteção de credenciais.
4. O front-end apresenta dados PIX completos em listagem administrativa: validar necessidade, minimização e registro de acesso em operação real.
5. Testar dupla revisão concorrente e confirmar que apenas uma decisão vence e que rejeição estorna exatamente uma vez.
6. Verificar os grants, RLS e segurança de todas RPCs de missão/indicação e balance audit em staging; a revisão do componente não substitui validação SQL.

## Testes sugeridos em staging
- Usuário comum não consegue executar RPC administrativa.
- Admin inativo não consegue executar RPCs após 0006.
- Aprovar pedido pending, e tentar revisar novamente: segunda tentativa deve falhar.
- Rejeitar pedido pending: saldo recuperado e reversal registrado; retry não deve estornar novamente.
- Duas decisões concorrentes: uma única decisão efetiva.
- Admin não pode desativar a própria conta.
- Consultar divergências não altera saldos.
- Validar acesso, logs e minimização dos dados PIX.

## Limites
Não executado em staging; build de frontend não prova comportamento das RPCs. Nenhuma migration foi aplicada ao banco live e nenhum saldo, usuário ou pedido real foi alterado.
