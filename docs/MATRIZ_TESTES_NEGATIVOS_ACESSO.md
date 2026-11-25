# Auditoria de acesso cruzado — matriz de testes negativos

**Status:** planejamento de testes de ataque controlado (SQL local/staging). Não executado no banco. Revisão das suites existentes `0001` a `0003` e migrations.

## Cobertura existente
- `0002_user_isolation.sql`: testa que dois usuários só contam seus próprios profiles e registros de ledger.
- `0003_ledger_immutability.sql`: verifica UPDATE/DELETE bloqueados no ledger e preservação do valor.
- RLS/grants e policies documentados em auditorias anteriores.

## Matriz negativa que ainda deve ser executada
| Identidade | Teste | Resultado esperado |
|---|---|---|
| anon | SELECT/INSERT/UPDATE em dados protegidos | negar |
| usuário A | leitura de profile/ledger/submission/referral de B | não retornar dados de B |
| usuário A | UPDATE points ou is_active em profile | negar |
| usuário A | INSERT/UPDATE/DELETE no ledger | negar |
| usuário A | UPDATE/DELETE de mission_claims | negar |
| usuário A | manipular submission/referral de B | negar |
| usuário comum | chamar RPC admin (saque, missão, indicação, usuários) | exceção de acesso admin |
| perfil inativo | RPCs de crédito, missão e indicação | negar |
| usuário comum | consultar app_admins diretamente | negar |
| authenticated | acesso direto a withdrawal_requests | negar enquanto grants não autorizam; validar caminho de leitura da UI |

## Execução
1. Criar banco local/staging descartável e aplicar migrations revisadas.
2. Preparar duas contas comuns, uma conta admin e uma conta inativa; fixtures isoladas.
3. Executar cada operação sob roles e claims JWT reais de teste.
4. Conferir resultado e estado pós-tentativa; assertions para negação devem validar erro ou zero linhas.
5. Envolver suite em transação/rollback; nunca testar no banco live.

## Limitações
As suites existentes de isolamento e ledger não cobrem ainda toda a matriz acima. O build do GitHub valida workflow, não executa pgTAP nem confirma RLS instalada em banco. Esta documentação não afirma que os ataques foram testados em runtime.

**Proteção operacional:** nenhuma alteração de banco ou dados live foi realizada.
