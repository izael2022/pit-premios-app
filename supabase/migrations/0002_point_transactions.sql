-- PIT PRÊMIOS: ledger append-only para auditoria de pontos.
-- Não aplicar automaticamente ao Supabase. Revisar/testar antes de executar.
create table if not exists public.point_transactions (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete restrict,
  amount bigint not null check (amount <> 0),
  transaction_type text not null check (transaction_type in ('reward','mission','referral','withdrawal','admin_adjustment','reversal')),
  description text not null default '',
  reference_id text,
  idempotency_key text,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);

create unique index if not exists point_transactions_user_idempotency
on public.point_transactions(user_id, idempotency_key)
where idempotency_key is not null;
create index if not exists point_transactions_user_created
on public.point_transactions(user_id, created_at desc);

alter table public.point_transactions enable row level security;
revoke all on public.point_transactions from anon, authenticated;
grant select on public.point_transactions to authenticated;

drop policy if exists point_transactions_select_own on public.point_transactions;
create policy point_transactions_select_own
on public.point_transactions for select
to authenticated using ((select auth.uid()) = user_id);

-- Tabela de registros somente leitura para usuários; escrita reservada ao backend/RPC futuro.
