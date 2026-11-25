-- PIT PRÊMIOS: fixa recompensa da missão manual no momento da submissão.
-- STAGED ONLY: não aplicar no banco live sem autorização.
alter table public.mission_submissions
 add column if not exists reward_points_snapshot bigint;

update public.mission_submissions s
 set reward_points_snapshot=m.reward_points
 from public.missions m
 where s.mission_id=m.id and s.reward_points_snapshot is null;

create or replace function public.submit_mission(p_mission_id bigint,p_proof text)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_id bigint; v_reward bigint; v_sub public.mission_submissions%rowtype;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if not exists(select 1 from public.profiles where id=v_uid and is_active=true) then raise exception 'inactive profile'; end if;
 if p_proof is null or length(trim(p_proof)) not between 1 and 2000 then raise exception 'invalid proof'; end if;
 select reward_points into v_reward from public.missions where id=p_mission_id and is_active=true and verification_mode='manual'
  and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>now()) for share;
 if not found then raise exception 'mission unavailable'; end if;
 if exists(select 1 from public.mission_claims where mission_id=p_mission_id and user_id=v_uid) then raise exception 'mission already rewarded'; end if;
 select * into v_sub from public.mission_submissions where mission_id=p_mission_id and user_id=v_uid for update;
 if found then
   if v_sub.status<>'rejected' then raise exception 'submission already exists'; end if;
   update public.mission_submissions set proof_text=trim(p_proof),status='pending',reviewed_by=null,reviewed_at=null,review_note='',created_at=now(),reward_points_snapshot=v_reward
   where id=v_sub.id returning id into v_id;
   return v_id;
 end if;
 insert into public.mission_submissions(mission_id,user_id,proof_text,reward_points_snapshot)
 values(p_mission_id,v_uid,trim(p_proof),v_reward) returning id into v_id;
 return v_id;
end; $$;

create or replace function public.admin_review_mission_submission(p_submission_id bigint,p_approve boolean,p_note text default '')
returns void language plpgsql security definer set search_path=public as $$
declare v_sub public.mission_submissions%rowtype; v_reward bigint;
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 if p_approve is null then raise exception 'decision required'; end if;
 if length(coalesce(p_note,''))>1000 then raise exception 'review note too long'; end if;
 select * into v_sub from public.mission_submissions where id=p_submission_id for update;
 if not found then raise exception 'submission not found'; end if;
 if v_sub.status<>'pending' then raise exception 'submission already reviewed'; end if;
 if p_approve then
   if v_sub.reward_points_snapshot is null or v_sub.reward_points_snapshot<=0 then raise exception 'reward snapshot missing'; end if;
   select id into v_reward from public.mission_claims where mission_id=v_sub.mission_id and user_id=v_sub.user_id;
   if found then raise exception 'mission already rewarded'; end if;
   insert into public.mission_claims(mission_id,user_id) values(v_sub.mission_id,v_sub.user_id);
   update public.profiles set points=points+v_sub.reward_points_snapshot,updated_at=now() where id=v_sub.user_id and is_active=true;
   if not found then raise exception 'inactive profile'; end if;
   insert into public.point_transactions(user_id,amount,transaction_type,description,reference_id,idempotency_key)
   values(v_sub.user_id,v_sub.reward_points_snapshot,'mission','Missão aprovada',v_sub.mission_id::text,'mission:'||v_sub.mission_id::text);
 end if;
 update public.mission_submissions set status=case when p_approve then 'approved' else 'rejected' end,reviewed_by=auth.uid(),reviewed_at=now(),review_note=coalesce(p_note,'')
 where id=p_submission_id and status='pending';
 if not found then raise exception 'submission review conflict'; end if;
end; $$;
revoke all on function public.submit_mission(bigint,text) from public,anon;
grant execute on function public.submit_mission(bigint,text) to authenticated;
revoke all on function public.admin_review_mission_submission(bigint,boolean,text) from public,anon;
grant execute on function public.admin_review_mission_submission(bigint,boolean,text) to authenticated;
