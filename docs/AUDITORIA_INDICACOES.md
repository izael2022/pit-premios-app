# Auditoria estática — indicações (referrals)

## Escopo
Migrations 0017–0021: tracking, revisão admin, listagem, atribuição via metadata de cadastro e hardening transacional.

## Controles observados
- Restrição unique(referred_id) evita associar múltiplos indicadores ao mesmo convidado.
- CHECK referrer_id<>referred_id e RPC register_referral impede autoindicação.
- register_referral exige auth e perfis ativos para ambos.
- A atribuição de cadastro valida formato UUID, não permite autoindicação e exige referrer ativo; inserção usa ON CONFLICT DO NOTHING.
- Revisão admin exige is_app_admin, valida decisão/recompensa/nota e lock FOR UPDATE.
- Hardening 0021 verifica atividade de ambos, idempotency ledger key, atualização do saldo e status condicional.

## Pontos de atenção
1. **Origem da atribuição:** o referrer vem de user metadata no signup; metadata não é segredo nem prova de comportamento legítimo. Avaliar controles antifraude posteriores antes de qualificar/creditar.
2. **Atividade e identidade:** contas ativas não demonstram que usuários são distintos ou legítimos; a análise de fraude não deve depender apenas do UUID.
3. **Atribuição não vinculada a critérios de qualificação:** no escopo 0017–0021, o referral nasce pending. Os critérios de qualificação parecem ser decisão administrativa, sem verificação automatizada de ações do convidado.
4. **Recompensa manual:** administrador define pontos na qualificação; revisar governança, limite, logs e aprovação dupla se valores forem altos.
5. **RLS/grants:** testar policies e permissões efetivas em staging, inclusive acesso de cada participante aos registros.
6. **Ledger e saldo:** testar atomicidade e idempotência com concorrência; o código documentado usa lock e key, mas não foi executado em staging.

## Testes sugeridos
- Autoindicação rejeitada por RPC e signup trigger.
- Tentativa de convidado com referrer inválido/inativo.
- Signup com referrer metadata válido, inválido e malformado.
- Duas atribuições para o mesmo convidado: só uma.
- Usuário não-admin tenta listar/revisar referrals.
- Admin inativo tenta aprovar.
- Aprovação/rejeição repetida e concorrente.
- Recompensa fora do intervalo e nota excessiva.
- Verificar saldo, ledger e status referral como operação atômica.

## Limites
Análise estática; nenhum teste executado em staging e nenhuma migration aplicada em produção.
