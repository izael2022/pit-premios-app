-- PIT PRÊMIOS: administração de missões manuais.
-- STAGED ONLY; não aplicar no banco live.
create or replace function public.admin_create_manual_mission(p_title text,p_description text,p_reward bigint,p_active boolean default false,p_start timestamptz default null,p_end timestamptz default null)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_id bigint;
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 if p_title is null or length(trim(p_title)) not between 1 and 120 then raise exception 'invalid title'; end if;
 if p_reward is null or p_reward<=0 or p_reward>1000000 then raise exception 'invalid reward'; end if;
 if p_end is not null and p_start is not null and p_end<=p_start then raise exception 'invalid period'; end if;
 insert into public.missions(title,description,reward_points,is_active,starts_at,ends_at,verification_mode)
 values(trim(p_title),coalesce(p_description,''),p_reward,p_active,p_start,p_end,'manual') returning id into v_id;
 return v_id;
end; $$;

create or replace function public.admin_list_mission_submissions()
returns table(id bigint,mission_id bigint,user_id uuid,proof_text text,status text,review_note text,created_at timestamptz,title text,reward_points bigint)
language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 return query select s.id,s.mission_id,s.user_id,s.proof_text,s.status,s.review_note,s.created_at,m.title,m.reward_points
 from public.mission_submissions s join public.missions m on m.id=s.mission_id
 order by s.created_at desc;
end; $$;
revoke all on function public.admin_create_manual_mission(text,text,bigint,boolean,timestamptz,timestamptz) from public,anon;
revoke all on function public.admin_list_mission_submissions() from public,anon;
grant execute on function public.admin_create_manual_mission(text,text,bigint,boolean,timestamptz,timestamptz) to authenticated;
grant execute on function public.admin_list_mission_submissions() to authenticated;
