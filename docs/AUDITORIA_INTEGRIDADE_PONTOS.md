# Auditoria estática — integridade do saldo e ledger de pontos

**Escopo:** revisão das migrações 0001–0002, 0006–0010, 0012–0016, 0021 e 0028, com foco em consistência saldo/ledger, duplicidade, transações e segurança. **Não executada em banco real.**

## Achados

1. **Saldo e ledger são dois registros separados.** As RPCs atualizam `profiles.points` e inserem em `point_transactions` dentro da mesma função/transaction, o que dá atomicidade quando ambas as operações ocorrem no mesmo bloco SQL. Entretanto, isso não prova que todo caminho de crédito existente no app segue esse padrão.
2. **Ledger append-only:** migration 0009 cria trigger que bloqueia UPDATE e DELETE. Proteção estática identificada.
3. **Idempotência:** há índice único parcial em `(user_id,idempotency_key)`. Essa proteção é útil, mas só se os caminhos de crédito usarem chave consistente e tratarem conflito corretamente.
4. **Créditos de missões automáticas:** `mission_claims` tem unique(mission_id,user_id), que impede claim repetido. O crédito e ledger são feitos na RPC. Deve-se validar com testes de concorrência.
5. **Missões manuais:** migração de snapshot fixa recompensa na submissão; a aprovação usa `mission_claims` para bloquear duplicidade e insere o ledger. A versão foi renumerada para 0028 porque a branch já continha outra migração 0027.
6. **Reconciliação:** existe relatório de auditoria administrativa anterior, mas é necessário validar empiricamente o método de reconciliação, especialmente reversões, saques, ajustes administrativos e créditos legados.
7. **Risco de divergência residual:** as migrações analisadas não demonstram que todo crédito do app está centralizado em uma RPC única; o teste de cobertura dos caminhos de crédito permanece pendente.

## Próximos testes recomendados em staging

- Crédito duplicado com mesmo idempotency key, para o mesmo usuário.
- Créditos simultâneos distintos e saldo final esperado.
- Tentativa de UPDATE/DELETE no ledger (deve falhar).
- Crédito, inserção no ledger e falha simulada: rollback completo.
- Reconciliar saldo por usuário com ledger considerando saques, reversões e ajustes.
- Testar aprovação manual concorrente e missão automática concorrente.
- Validar que todas as RPCs relevantes não podem ser executadas por anon e que verificam perfil ativo.

## Limites

Auditoria estática de arquivos. Nenhum SQL foi executado em staging ou produção. Nenhuma alteração no banco, usuários ou saldo foi feita. O build do frontend não valida sintaxe ou comportamento SQL.
