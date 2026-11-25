-- PIT PRÊMIOS: listagem segura de indicações para painel admin.
-- STAGED ONLY.
create or replace function public.admin_list_referrals()
returns table(id bigint,referrer_id uuid,referred_id uuid,status text,qualification_note text,created_at timestamptz,qualified_at timestamptz)
language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 return query select r.id,r.referrer_id,r.referred_id,r.status,r.qualification_note,r.created_at,r.qualified_at from public.referrals r order by r.created_at desc limit 500;
end; $$;
revoke all on function public.admin_list_referrals() from public,anon;
grant execute on function public.admin_list_referrals() to authenticated;
