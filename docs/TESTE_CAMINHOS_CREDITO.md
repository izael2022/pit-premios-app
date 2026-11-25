# Teste estrutural dos caminhos de crédito

Arquivo `supabase/tests/0005_credit_path_integrity_structure.sql`.

## Verificações
1. claim automático insere claim de missão.
2. claim automático inclui inserção no ledger.
3. claim automático atualiza saldo.
4. revisão de indicação bloqueia a linha.
5. revisão de indicação usa idempotency key.
6. índice único do ledger contempla chave de idempotência.

Execute apenas em banco local ou staging descartável após todas as migrations. Script sem fixtures de negócio e com rollback. Não executado contra banco nesta etapa.

## Limitação
Inspeção estrutural não prova atomicidade nem comportamento concorrente. Para isso, são necessários testes de chamadas simultâneas em staging, com usuários e missões fictícias e observação de saldo/ledger antes e depois.
