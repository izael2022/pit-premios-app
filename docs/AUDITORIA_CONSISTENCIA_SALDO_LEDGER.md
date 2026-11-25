# Auditoria de consistência de saldo e ledger — PIT PRÊMIOS

## Escopo
Análise estática das migrations 0001, 0002, 0006 e 0009 na branch reconstrucao-pit-premios. Não foi feita conexão nem alteração ao banco de produção.

## Observações verificadas no código
- `profiles.points` é o saldo operacional e possui CHECK para impedir valores negativos (migration 0001).
- `point_transactions` registra transações, tem valor não-zero, tipos permitidos e chave de idempotência opcional única por usuário (migration 0002).
- O ledger tem RLS de leitura própria; grants de escrita são revogados para anon/authenticated, indicando escrita prevista por backend/RPC (migration 0002).
- A função `request_withdrawal` atualiza o saldo somente se há saldo suficiente e registra o ledger negativo e pedido de saque na mesma função/transaction context (migration 0006). Ela valida mínimo de 10.000 pontos e incrementos de 1.000.
- Trigger da migration 0009 impede UPDATE/DELETE no ledger.

## Riscos / lacunas
1. A auditoria não encontrou, neste conjunto de migrations, um RPC geral de crédito de pontos que centralize saldo e ledger.
2. Como a chave de idempotência é opcional, as operações que concedem pontos precisam sempre fornecer chave de idempotência para evitar duplicações em reenvios.
3. Não se deve presumir que `profiles.points` equivale à soma do ledger: saldo inicial, histórico anterior e eventuais operações legadas podem não estar representados. É necessário definir uma regra de reconciliação e baseline antes de criar teste de igualdade.
4. O ledger append-only não impede sozinho créditos duplicados, nem garante que todo ajuste de saldo gere uma transação correspondente; isso depende de RPCs/serviços autorizados e transações atômicas.
5. Testes de concorrência, repetição/idempotência, consistência em rollback e reconciliação devem ser executados em staging/local.

## Contrato de segurança recomendado para próximos RPCs
- Toda operação de pontos altera saldo e insere ledger na mesma transação.
- Sempre use idempotency_key obrigatória para recompensas e créditos repetíveis.
- Validar usuário ativo e autorização no servidor, não no cliente.
- Condicionar update do saldo a saldo suficiente e verificar número de linhas afetadas.
- Evitar operações de escrita direta pelo cliente; grants e RLS devem manter isso bloqueado.
- Definir mecanismo auditável de baseline/reconciliação sem alterar dados históricos automaticamente.

## Status
Auditoria estática documentada. Não é prova de teste executado. Nenhuma migração foi aplicada e nenhum dado de produção foi alterado.
