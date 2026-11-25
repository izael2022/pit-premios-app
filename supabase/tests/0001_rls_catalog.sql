-- Testes iniciais de catálogo/RLS para PIT PRÊMIOS.
-- Execute SOMENTE em Supabase local/staging isolado. Transação rollback.
begin;
select plan(6);

select has_table('public','profiles','Tabela profiles existe');
select has_table('public','point_transactions','Tabela point_transactions existe');

select ok(
  (select relrowsecurity from pg_class where oid='public.profiles'::regclass),
  'RLS habilitada em profiles'
);
select ok(
  (select relrowsecurity from pg_class where oid='public.point_transactions'::regclass),
  'RLS habilitada em point_transactions'
);

select ok(
  exists(select 1 from pg_policies where schemaname='public' and tablename='profiles' and policyname='profiles_select_own'),
  'Policy profiles_select_own existe'
);
select ok(
  exists(select 1 from pg_policies where schemaname='public' and tablename='point_transactions' and policyname='point_transactions_select_own'),
  'Policy point_transactions_select_own existe'
);

select * from finish();
rollback;
