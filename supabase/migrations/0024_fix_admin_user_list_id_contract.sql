-- Corrige o contrato da RPC admin_list_users: o frontend usa x.id.
-- STAGED ONLY; não aplicar ao Supabase live sem autorização.
drop function if exists public.admin_list_users(text);
create function public.admin_list_users(p_search text default null)
returns table(id uuid,display_name text,points bigint,is_active boolean,created_at timestamptz)
language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 return query
 select p.id,p.display_name,p.points,p.is_active,p.created_at
 from public.profiles p
 where p_search is null or p_search='' or p.display_name ilike '%'||p_search||'%' or p.id::text ilike '%'||p_search||'%'
 order by p.created_at desc limit 300;
end; $$;
revoke all on function public.admin_list_users(text) from public,anon;
grant execute on function public.admin_list_users(text) to authenticated;
