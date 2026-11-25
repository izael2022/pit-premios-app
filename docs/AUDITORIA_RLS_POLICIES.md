# Auditoria RLS — revisão de policies e grants

**Escopo:** revisão estática das migrations da branch `reconstrucao-pit-premios`. Não consulta nem altera o banco live.

## Inventário de achados

### 1. `withdrawal_requests` — RLS ativada, sem policy visível nas migrations examinadas
A tabela tem RLS ativada e grants revogados para `anon,authenticated`. A leitura e revisão administrativa aparecem via RPC. Não foi encontrada policy SELECT para que um usuário consulte os próprios pedidos. Se a app depende de leitura direta da tabela, o acesso não funcionará; isso é um possível problema de funcionalidade, não vazamento. Confirmar necessidade e API de consumo.

### 2. `app_admins` — sem acesso direto (deny-by-default)
RLS ativada e todos os grants revogados. As funções administrativas consultam a tabela em contexto SECURITY DEFINER. Não há policy de leitura direta, o que é adequado para evitar exposição da lista de admins.

### 3. `profiles` — isolamento de leitura próprio e perfil ativo
A policy de leitura foi reforçada para exigir `auth.uid()=id` e perfil ativo. Inserção inicial limitada ao próprio UID e saldo zero na migration inicial. Não há policy de UPDATE para clientes, evitando alteração direta de pontos/estado.

### 4. `point_transactions` — ledger read-only e isolamento
Grant SELECT para authenticated, RLS e policy de leitura própria; migrations subsequentes condicionam acesso a perfil ativo. Grants de escrita revogados.

### 5. `missions` / `mission_claims`
RLS ativada; missões só visíveis quando ativas; claims somente do próprio usuário. Grants de escrita cliente revogados.

### 6. `mission_submissions`
RLS ativa e grants revogados; policy de leitura do próprio usuário. Submissões e revisão usam RPCs protegidas.

### 7. `referrals`
RLS ativa, grants revogados e policy SELECT limitada aos participantes (referrer ou indicado). Cadastro/qualificação via RPC/trigger.

## Limitações / próximos testes
- Revisão estática das migrations, não valida policies/grants instalados no banco atual.
- A tabela de saques pode precisar de policy SELECT own, mas antes deve-se confirmar o caminho real do app; grants revogados significam que policy sozinha não basta.
- Testar matriz anon, usuário A, usuário B, admin, admin inativo; SELECT/INSERT/UPDATE/DELETE em cada tabela, RPC e acesso via API.
- O teste de catálogo deve usar banco local/staging, fixtures e rollback; nunca executar diretamente em produção.

## Proteção operacional
Nenhuma migration aplicada. Nenhum saldo, usuário, dado ou tabela de produção foi alterado.
