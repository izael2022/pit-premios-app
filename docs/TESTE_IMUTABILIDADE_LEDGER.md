# Teste de integridade append-only do ledger

## Objetivo
Validar em ambiente local/staging que o trigger da migration 0009 impede alterações e exclusões de registros do ledger de pontos.

## Teste preparado
Arquivo: `supabase/tests/0003_ledger_immutability.sql`

- Tenta alterar o valor de um registro de fixture e espera a exceção do trigger.
- Tenta excluir o registro e espera a mesma exceção.
- Confirma que o valor original continua sendo 500.
- Usa fixture de usuário e registro em transação com rollback.

## Execução
Execute exclusivamente em Supabase local/staging descartável, após migrations, usando `supabase test db`. Não execute em produção. O GitHub Actions de build não executa automaticamente pgTAP; este arquivo está preparado, não é uma execução de teste reportada.

## Limite
Este teste cobre o trigger append-only em execução sob o contexto que o executa. Não valida permissões/RLS efetivas, reconciliação de saldo, concorrência ou fluxos de saque.
