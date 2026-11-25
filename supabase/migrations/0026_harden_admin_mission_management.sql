-- PIT PRÊMIOS: hardening adicional das RPCs administrativas de missões.
-- STAGED ONLY: não aplicar no Supabase de produção sem autorização explícita.

create or replace function public.admin_set_mission_active(p_id bigint,p_active boolean)
returns void language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 if p_id is null or p_active is null then raise exception 'invalid mission activation input'; end if;
 update public.missions set is_active=p_active,updated_at=now() where id=p_id;
 if not found then raise exception 'mission not found'; end if;
end; $$;

create or replace function public.admin_list_missions()
returns table(id bigint,title text,description text,reward_points bigint,is_active boolean,starts_at timestamptz,ends_at timestamptz,created_at timestamptz)
language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 return query select m.id,m.title,m.description,m.reward_points,m.is_active,m.starts_at,m.ends_at,m.created_at
 from public.missions m order by m.created_at desc limit 500;
end; $$;

revoke all on function public.admin_set_mission_active(bigint,boolean) from public,anon;
revoke all on function public.admin_list_missions() from public,anon;
grant execute on function public.admin_set_mission_active(bigint,boolean) to authenticated;
grant execute on function public.admin_list_missions() to authenticated;
