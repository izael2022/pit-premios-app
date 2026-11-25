-- PIT PRÊMIOS: ledger append-only adicional.
-- STAGED ONLY: não aplicar no banco de produção sem autorização explícita.

create or replace function public.prevent_point_transaction_mutation()
returns trigger language plpgsql set search_path=public as $$
begin
 raise exception 'point transactions are append-only';
end;
$$;

drop trigger if exists point_transactions_immutable on public.point_transactions;
create trigger point_transactions_immutable
before update or delete on public.point_transactions
for each row execute function public.prevent_point_transaction_mutation();

revoke all on function public.prevent_point_transaction_mutation() from public,anon,authenticated;
