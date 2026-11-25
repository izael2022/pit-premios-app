# pgTAP inicial — PIT PRÊMIOS

Este diretório contém um primeiro teste automatizado de catálogo e configuração RLS, não testes de isolamento entre usuários.

## Segurança de execução
- Rodar apenas em Supabase local ou staging descartável, nunca no projeto de produção.
- Teste usa transação e rollback.
- Não cria, modifica ou apaga dados de usuários.
- A execução exige schema migrado e pgTAP disponível.

## Executar localmente
Com Supabase CLI configurado no ambiente local:
```bash
supabase test db
```

## Escopo atual
- Confirma existência de `profiles` e `point_transactions`.
- Confirma RLS habilitada nessas tabelas.
- Confirma policies `profiles_select_own` e `point_transactions_select_own`.

## Limitação
Essas assertions verificam configuração no catálogo, não comprovam que um usuário A esteja impedido de acessar os dados de B. Testes de isolamento com usuários simulados e JWT/role serão acrescentados após validar um ambiente local de teste e os mecanismos de criação de usuários de teste.
