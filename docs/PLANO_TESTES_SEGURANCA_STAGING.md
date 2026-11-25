# Plano de testes de segurança isolados — PIT PRÊMIOS

Este plano é um roteiro para staging/local. Não deve ser executado na instância de produção. Não contém credenciais e não aplica alterações.

## Pré-requisitos
- Supabase local ou staging separado, com dados fictícios.
- Dois usuários comuns e uma conta admin de teste.
- Dados de teste descartáveis; nunca copiar dados pessoais reais.
- Snapshot/backup do ambiente de teste antes dos testes.

## Testes negativos (executar como usuário autenticado)
1. **Isolamento de perfil:** usuário A tenta ler perfil de B e editar campos de B. Esperado: nenhuma leitura/alteração não autorizada.
2. **Ledger:** usuário A tenta inserir, atualizar ou apagar pontos diretamente. Esperado: rejeição por permissões/RLS/trigger.
3. **RPC administrativa:** usuário comum chama RPCs administrativas diretamente, sem interface. Esperado: rejeição.
4. **Usuário inativo:** testar RPCs de negócio após desativação de conta. Esperado: bloqueio consistente.
5. **Missão duplicada:** duas sessões de A tentam reivindicar a mesma missão simultaneamente. Esperado: apenas uma recompensa contabilizada.
6. **Submissão manual:** repetir aprovação/rejeição e tentar revisar duas vezes. Esperado: operação idempotente e estados consistentes.
7. **Indicação:** tentar autoindicação, indicação duplicada e revisão simultânea. Esperado: nenhuma recompensa indevida.
8. **Saque:** duas solicitações simultâneas, abaixo do mínimo, saldo insuficiente e tentativa de repetição. Esperado: apenas solicitações válidas e sem duplicidade.
9. **Revisão/estorno:** repetir a ação administrativa e testar concorrência. Esperado: uma única transição e ledger consistente.
10. **Campos malformados:** valores negativos, nulos, tipos incorretos, texto excessivo e parâmetros inesperados. Esperado: validação server-side.

## Registro de resultados
Para cada caso, registrar: ambiente, data, usuário de teste, comando/API usado, resultado esperado, resultado observado, evidência sem dados pessoais, status PASS/FAIL e issue/commit de correção.

## Consultas de inventário (somente leitura, staging/local)
Use o SQL Editor ou psql no ambiente isolado para inventariar policies e privilégios. Não execute scripts de limpeza ou reset contra produção.

### Policies
```sql
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
order by tablename, policyname;
```

### Privilégios de tabelas
```sql
select table_schema, table_name, grantee, privilege_type
from information_schema.table_privileges
where table_schema = 'public'
order by table_name, grantee, privilege_type;
```

### Funções e SECURITY DEFINER
```sql
select n.nspname as schema_name, p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef as security_definer,
       p.proconfig as configuration,
       p.proacl as acl
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
order by p.proname;
```

## Ferramenta sugerida
pgTAP pode automatizar assertions de RLS e permissões em banco local, com transações que rollback ao fim. Consulte a documentação Supabase sobre testes RLS. Antes de criar assertions definitivas, validar os nomes reais das tabelas e funções da versão do schema usada em staging.

## Segurança operacional
- Nunca executar estes testes na produção.
- Nunca usar saldo, contas, saques ou usuários reais.
- Não aplicar migration de correção sem autorização explícita e teste prévio.
- Um build frontend não valida políticas SQL nem estado efetivo de RLS.
