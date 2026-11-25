-- Teste estrutural de idempotência e atomicidade em caminhos de crédito.
-- Somente local/staging após migrations. Não altera dados; rollback.
begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

select ok(
 exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='public' and p.proname='claim_mission'
          and pg_get_functiondef(p.oid) ilike '%mission_claims%'),
 'claim_mission insere claim que impede resgate repetido'
);

select ok(
 exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='public' and p.proname='claim_mission'
          and pg_get_functiondef(p.oid) ilike '%point_transactions%'),
 'claim_mission registra crédito no ledger'
);

select ok(
 exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='public' and p.proname='claim_mission'
          and pg_get_functiondef(p.oid) ilike '%profiles%'),
 'claim_mission atualiza saldo do perfil'
);

select ok(
 exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='public' and p.proname='admin_review_referral'
          and pg_get_functiondef(p.oid) ilike '%for update%'),
 'revisão de indicação bloqueia linha para evitar corrida'
);

select ok(
 exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='public' and p.proname='admin_review_referral'
          and pg_get_functiondef(p.oid) ilike '%idempotency_key%'),
 'recompensa de indicação usa chave idempotente'
);

select ok(
 exists(select 1 from pg_indexes where schemaname='public' and tablename='point_transactions'
        and indexdef ilike '%unique%' and indexdef ilike '%idempotency_key%'),
 'ledger possui índice único para chave de idempotência'
);

select * from finish();
rollback;
