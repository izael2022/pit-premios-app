-- PIT PRÊMIOS: bloqueio de leitura do ledger para perfis desativados.
-- STAGED ONLY. Não aplicar sem autorização explícita.
drop policy if exists point_transactions_select_own on public.point_transactions;
create policy point_transactions_select_own
on public.point_transactions for select to authenticated
using (
 (select auth.uid()) = user_id
 and exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_active=true)
);
