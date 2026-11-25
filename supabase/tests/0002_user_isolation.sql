-- Teste de isolamento de leitura entre usuários para profiles e ledger.
-- Execute exclusivamente em Supabase local/staging descartável, após migrations.
-- Fixture inserida antes de assumir role authenticated; transação revertida.
begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

insert into auth.users (id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
 ('11111111-1111-4111-8111-111111111111','authenticated','authenticated','rls-a@example.test','{}','{"display_name":"Teste A"}',now(),now()),
 ('22222222-2222-4222-8222-222222222222','authenticated','authenticated','rls-b@example.test','{}','{"display_name":"Teste B"}',now(),now())
on conflict (id) do nothing;

insert into public.point_transactions(user_id,amount,transaction_type,description)
values
 ('11111111-1111-4111-8111-111111111111',100,'reward','Fixture RLS A'),
 ('22222222-2222-4222-8222-222222222222',200,'reward','Fixture RLS B');

set local role authenticated;
set local request.jwt.claim.sub='11111111-1111-4111-8111-111111111111';
select results_eq('select count(*) from public.profiles',array[1::bigint],'Usuário A vê apenas o perfil A');
select results_eq('select count(*) from public.point_transactions',array[1::bigint],'Usuário A vê apenas o registro de ledger A');

set local request.jwt.claim.sub='22222222-2222-4222-8222-222222222222';
select results_eq('select count(*) from public.profiles',array[1::bigint],'Usuário B vê apenas o perfil B');
select results_eq('select count(*) from public.point_transactions',array[1::bigint],'Usuário B vê apenas o registro de ledger B');

select * from finish();
rollback;
