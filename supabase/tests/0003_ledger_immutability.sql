-- Teste de integridade append-only do ledger de pontos.
-- Execute somente em banco local/staging descartável, após migrations.
-- Nunca execute em produção; fixtures e assertions estão dentro de rollback.
begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

insert into auth.users (id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values ('33333333-3333-4333-8333-333333333333','authenticated','authenticated','ledger-test@example.test','{}','{}',now(),now())
on conflict (id) do nothing;

insert into public.point_transactions(user_id,amount,transaction_type,description,idempotency_key)
values ('33333333-3333-4333-8333-333333333333',500,'reward','Fixture append-only','ledger-test-key');

select throws_ok(
 $$update public.point_transactions set amount=900 where idempotency_key='ledger-test-key'$$,
 'P0001', 'point transactions are append-only',
 'Ledger impede alteração de valor'
);
select throws_ok(
 $$delete from public.point_transactions where idempotency_key='ledger-test-key'$$,
 'P0001', 'point transactions are append-only',
 'Ledger impede exclusão de registro'
);
select results_eq(
 $$select amount from public.point_transactions where idempotency_key='ledger-test-key'$$,
 array[500::bigint],
 'Valor original permanece intacto após tentativas bloqueadas'
);
select * from finish();
rollback;
