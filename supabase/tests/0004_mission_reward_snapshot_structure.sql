-- Verificações estruturais da proteção de recompensa de missão manual.
-- Execute apenas em Supabase local/staging descartável após todas as migrations.
-- Este teste NÃO cria usuários, créditos ou submissões; transação termina em rollback.
begin;
create extension if not exists pgtap with schema extensions;
select plan(5);

select has_column('public','mission_submissions','reward_points_snapshot',
 'Submissões armazenam snapshot da recompensa');

select ok(
  exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
         where n.nspname='public' and p.proname='submit_mission'
           and pg_get_functiondef(p.oid) ilike '%reward_points_snapshot%'),
  'submit_mission usa snapshot de recompensa'
);

select ok(
  exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
         where n.nspname='public' and p.proname='admin_review_mission_submission'
           and pg_get_functiondef(p.oid) ilike '%reward_points_snapshot%'),
  'admin review utiliza recompensa congelada'
);

select ok(
  exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
         where n.nspname='public' and p.proname='admin_review_mission_submission'
           and pg_get_functiondef(p.oid) ilike '%mission already rewarded%'),
  'revisão bloqueia missão já recompensada'
);

select ok(
  exists(select 1 from pg_indexes where schemaname='public'
         and tablename='point_transactions'
         and indexdef ilike '%user_id%idempotency_key%'),
  'ledger possui índice de idempotência (verificar definição completa)'
);

select * from finish();
rollback;
