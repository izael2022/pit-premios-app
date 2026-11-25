# Provisionamento inicial do administrador — PIT PRÊMIOS

**Este procedimento é manual e não automatizado.** Não existe endpoint público de autoelevação.

## Pré-requisitos
1. Revisar e aplicar as migrations 0001–0004 em ambiente de teste primeiro.
2. Criar a conta do proprietário pela tela de cadastro.
3. No Supabase Dashboard, abrir Authentication → Users e copiar o UUID exato da conta do proprietário.
4. Confirmar que o UUID corresponde à conta correta antes de executar.

## Provisionamento
No SQL Editor do Supabase, executar substituindo `OWNER_AUTH_UUID` pelo UUID copiado (sem os sinais de placeholder):

```sql
insert into public.app_admins (user_id, granted_by)
values ('OWNER_AUTH_UUID'::uuid, 'OWNER_AUTH_UUID'::uuid)
on conflict (user_id) do nothing;
```

## Verificação
Logar com a conta provisionada e verificar:
- `is_app_admin()` retorna true;
- o painel administrativo é exibido;
- lista de solicitações é acessível.

## Segurança
- Não compartilhe nem exponha credenciais, service-role keys ou tokens.
- Nunca insira UUID de usuário não verificado.
- Não execute esse script automaticamente em CI/CD.
- A aprovação de saque não realiza pagamento PIX; o pagamento permanece manual.
- Rejeitar saque faz estorno via RPC; conferir cuidadosamente antes da ação.

Este arquivo é apenas documentação. Nenhuma migration foi aplicada e nenhum dado foi alterado.
