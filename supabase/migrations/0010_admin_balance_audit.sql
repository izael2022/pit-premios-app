-- PIT PRÊMIOS: diagnóstico de divergência entre saldo atual e ledger.
-- STAGED ONLY. Não executa correção nem altera saldo.
create or replace function public.admin_audit_point_balances()
returns table(user_id uuid,display_name text,profile_points bigint,ledger_net bigint,difference bigint,ledger_entries bigint)
language plpgsql security definer set search_path=public as $$
begin
 if not public.is_app_admin() then raise exception 'admin access required'; end if;
 return query
 select p.id,p.display_name,p.points,
        coalesce(sum(t.amount),0)::bigint,
        (p.points-coalesce(sum(t.amount),0))::bigint,
        count(t.id)::bigint
 from public.profiles p
 left join public.point_transactions t on t.user_id=p.id
 group by p.id,p.display_name,p.points
 having p.points <> coalesce(sum(t.amount),0)
 order by abs(p.points-coalesce(sum(t.amount),0)) desc,p.created_at asc;
end; $$;
revoke all on function public.admin_audit_point_balances() from public,anon;
grant execute on function public.admin_audit_point_balances() to authenticated;
