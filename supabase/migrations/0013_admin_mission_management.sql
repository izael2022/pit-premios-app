-- PIT PRÊMIOS: RPCs administrativas para gerenciar missões.
-- STAGED ONLY; não aplicada ao banco live.
create or replace function public.admin_create_mission(p_title text,p_description text,p_reward bigint,p_active boolean default false,p_start timestamptz default null,p_end timestamptz default null)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_id bigint;
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 if p_title is null or length(trim(p_title)) not between 1 and 120 then raise exception 'invalid title'; end if;
 if p_reward is null or p_reward<=0 or p_reward>1000000 then raise exception 'invalid reward'; end if;
 if p_end is not null and p_start is not null and p_end<=p_start then raise exception 'invalid period'; end if;
 insert into public.missions(title,description,reward_points,is_active,starts_at,ends_at)
 values(trim(p_title),coalesce(p_description,''),p_reward,p_active,p_start,p_end) returning id into v_id;
 return v_id;
end; $$;

create or replace function public.admin_update_mission(p_id bigint,p_title text,p_description text,p_reward bigint,p_start timestamptz,p_end timestamptz)
returns void language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 if p_id is null or p_title is null or length(trim(p_title)) not between 1 and 120 then raise exception 'invalid title'; end if;
 if p_reward is null or p_reward<=0 or p_reward>1000000 then raise exception 'invalid reward'; end if;
 if p_end is not null and p_start is not null and p_end<=p_start then raise exception 'invalid period'; end if;
 update public.missions set title=trim(p_title),description=coalesce(p_description,''),reward_points=p_reward,starts_at=p_start,ends_at=p_end,updated_at=now() where id=p_id;
 if not found then raise exception 'mission not found'; end if;
end; $$;

create or replace function public.admin_set_mission_active(p_id bigint,p_active boolean)
returns void language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 update public.missions set is_active=p_active,updated_at=now() where id=p_id;
 if not found then raise exception 'mission not found'; end if;
end; $$;

create or replace function public.admin_list_missions()
returns table(id bigint,title text,description text,reward_points bigint,is_active boolean,starts_at timestamptz,ends_at timestamptz,created_at timestamptz)
language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 return query select m.id,m.title,m.description,m.reward_points,m.is_active,m.starts_at,m.ends_at,m.created_at from public.missions m order by m.created_at desc;
end; $$;

revoke all on function public.admin_create_mission(text,text,bigint,boolean,timestamptz,timestamptz) from public,anon;
revoke all on function public.admin_update_mission(bigint,text,text,bigint,timestamptz,timestamptz) from public,anon;
revoke all on function public.admin_set_mission_active(bigint,boolean) from public,anon;
revoke all on function public.admin_list_missions() from public,anon;
grant execute on function public.admin_create_mission(text,text,bigint,boolean,timestamptz,timestamptz) to authenticated;
grant execute on function public.admin_update_mission(bigint,text,text,bigint,timestamptz,timestamptz) to authenticated;
grant execute on function public.admin_set_mission_active(bigint,boolean) to authenticated;
grant execute on function public.admin_list_missions() to authenticated;
