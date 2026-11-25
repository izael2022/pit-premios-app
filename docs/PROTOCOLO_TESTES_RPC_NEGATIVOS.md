# Testes negativos de RPC e contas inativas — protocolo

**Status:** protocolo de execução; não executado em banco. Baseado na leitura estática de migrations.

## RPCs identificadas
- `claim_mission(bigint)`: exige UID autenticado, profile ativo, missão ativa e disponível; registra claim e crédito.
- `register_referral(uuid)`: exige UID, bloqueia auto-indicação e exige ambas as contas ativas.
- `admin_list_users(text)` e `admin_set_user_active(uuid,boolean)`: exigem admin; a segunda também bloqueia desativar a própria conta.

## Casos de teste para staging isolado
1. **Claim sem autenticação:** executar `claim_mission` sem claim JWT. Esperado: erro `authentication required`.
2. **Claim com profile inativo:** fixture de usuário inativo, claim JWT correspondente. Esperado: `inactive profile`.
3. **Missão inexistente/inativa/fora da janela:** claim. Esperado: `mission unavailable`; sem transação de ledger ou alteração de saldo.
4. **Claim repetido:** mesma conta/missão duas vezes. Esperado: segundo pedido falha pela unicidade; apenas um crédito/ledger.
5. **Auto-indicação:** `register_referral(auth.uid())`. Esperado: `self referral not allowed`.
6. **Conta inativa na indicação:** inativa (referrer ou referred). Esperado: `active accounts required`; nenhuma referral criada.
7. **Usuário comum em RPC admin:** chamar `admin_list_users` e `admin_set_user_active` com conta não-admin. Esperado: `admin access required`; nenhum estado alterado.
8. **Admin desativando a si próprio:** `admin_set_user_active(auth.uid(),false)`. Esperado: `cannot disable own account`.

## Verificações pós-tentativa
Para cada erro, comparar profile.points, ledger, claims/referrals e estado de usuários antes/depois. Testar em banco local ou staging descartável, usando fixtures e rollback; não executar no live.

## Limitação
Os casos são derivados das mensagens e condições das funções nas migrations, e ainda não foram executados em runtime. Build do CI não comprova comportamento do banco.
