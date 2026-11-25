-- PIT PRÊMIOS: protege a ativação de perfis e evita desativar contas administrativas.
-- STAGED ONLY; não aplicar ao Supabase live sem autorização.
create or replace function public.admin_set_user_active(p_user_id uuid,p_active boolean)
returns void language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 if p_user_id is null or p_active is null then raise exception 'user and active state are required'; end if;
 if p_user_id=auth.uid() then raise exception 'cannot change own active state'; end if;
 if exists(select 1 from public.app_admins where user_id=p_user_id) then
   raise exception 'cannot deactivate or change another admin profile here';
 end if;
 update public.profiles set is_active=p_active,updated_at=now() where id=p_user_id;
 if not found then raise exception 'user not found'; end if;
end; $$;
revoke all on function public.admin_set_user_active(uuid,boolean) from public,anon;
grant execute on function public.admin_set_user_active(uuid,boolean) to authenticated;
