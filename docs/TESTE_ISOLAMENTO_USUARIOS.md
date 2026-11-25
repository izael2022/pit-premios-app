# Teste de isolamento RLS — dois usuários

## Segurança
Executar somente em Supabase local ou staging isolado. O script usa uma transação e termina em rollback. Não executá-lo em produção.

## Cobertura
- Usuário A consulta profiles e deve ver somente seu perfil.
- Usuário A consulta point_transactions e deve ver somente seu registro fixture.
- Usuário B faz as mesmas verificações.
- Fixtures usam UUIDs dedicados e emails de teste.

## Execução
Após configurar o Supabase local e aplicar migrations localmente:
```bash
supabase test db
```

O teste depende de pgTAP disponível e das migrations aplicadas no banco de teste. A execução ainda precisa ser realizada no ambiente local/staging; o CI de frontend não executa SQL/pgTAP.
