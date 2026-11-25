# Teste estrutural — snapshot de recompensa de missão

**Escopo:** validar, em banco local/staging isolado, a existência do snapshot e os guardrails das funções de submissão/revisão.

## Arquivo
`supabase/tests/0004_mission_reward_snapshot_structure.sql`

O teste valida:
- coluna `reward_points_snapshot`;
- função `submit_mission` referenciando o snapshot;
- função de revisão usando o snapshot;
- proteção contra missão já recompensada;
- índice de idempotência do ledger.

## Execução
Execute somente após todas as migrations em ambiente descartável/local ou staging. O script abre uma transação e termina em `ROLLBACK`. Não execute em produção.

## Limites
Este teste é estrutural: não simula aprovação real, concorrência, nem créditos. Essas verificações exigem fixtures de usuários/admin em staging e chamadas concorrentes. O CI de frontend não executa pgTAP.

## Resultado esperado
5 assertions aprovadas. Se falhar, interrompa o processo e investigue o schema/function definition antes de aplicar qualquer alteração.
