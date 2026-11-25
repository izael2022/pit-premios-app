-- PIT PRÊMIOS: relatório somente leitura para auditoria de saldo/ledger.
-- STAGED ONLY: não aplicar no banco live sem autorização explícita.
create or replace function public.admin_audit_point_integrity()
returns table(user_id uuid,display_name text,is_active boolean,profile_points bigint,ledger_net bigint,difference bigint,ledger_entries bigint,last_ledger_at timestamptz)
language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 return query
 with ledger as (
   select t.user_id,sum(t.amount)::bigint as net,count(*)::bigint as entries,max(t.created_at) as last_at
   from public.point_transactions t group by t.user_id
 )
 select p.id,p.display_name,p.is_active,p.points,coalesce(l.net,0),
        (p.points-coalesce(l.net,0))::bigint,coalesce(l.entries,0),l.last_at
 from public.profiles p left join ledger l on l.user_id=p.id
 order by abs(p.points-coalesce(l.net,0)) desc,p.created_at asc
 limit 1000;
end; $$;
revoke all on function public.admin_audit_point_integrity() from public,anon;
grant execute on function public.admin_audit_point_integrity() to authenticated;
