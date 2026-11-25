-- Gestão administrativa de usuários: migration staged, NOT applied.
alter table public.profiles add column if not exists is_active boolean not null default true;

create or replace function public.admin_list_users(p_search text default null)
returns table(user_id uuid,display_name text,points bigint,is_active boolean,created_at timestamptz)
language plpgsql security definer set search_path=public as $$
begin
 if not public.is_app_admin() then raise exception 'admin access required'; end if;
 return query select p.id,p.display_name,p.points,p.is_active,p.created_at
 from public.profiles p
 where p_search is null or p_search='' or p.display_name ilike '%'||p_search||'%' or p.id::text ilike '%'||p_search||'%'
 order by p.created_at desc limit 300;
end; $$;
revoke all on function public.admin_list_users(text) from public,anon;
grant execute on function public.admin_list_users(text) to authenticated;

create or replace function public.admin_set_user_active(p_user_id uuid,p_active boolean)
returns void language plpgsql security definer set search_path=public as $$
begin
 if not public.is_app_admin() then raise exception 'admin access required'; end if;
 if p_user_id=auth.uid() then raise exception 'cannot disable own account'; end if;
 update public.profiles set is_active=p_active,updated_at=now() where id=p_user_id;
 if not found then raise exception 'user not found'; end if;
end; $$;
revoke all on function public.admin_set_user_active(uuid,boolean) from public,anon;
grant execute on function public.admin_set_user_active(uuid,boolean) to authenticated;
