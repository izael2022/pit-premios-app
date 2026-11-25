-- PIT PRÊMIOS: proteção adicional para submissões e revisão.
-- STAGED ONLY: não aplicar no banco live sem autorização.
-- A função de revisão já usa lock da submissão; este patch valida nota e protege
-- de revisão malformada, mantendo a recompensa e o status na mesma transação.
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
  select reward_points into v_reward from public.missions where id=v_sub.mission_id and is_active=true and verification_mode='manual'
   and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>now()) for share;
  if not found then raise exception 'mission unavailable'; end if;
  insert into public.mission_claims(mission_id,user_id) values(v_sub.mission_id,v_sub.user_id);
  update public.profiles set points=points+v_reward,updated_at=now() where id=v_sub.user_id and is_active=true;
  if not found then raise exception 'inactive profile'; end if;
  insert into public.point_transactions(user_id,amount,transaction_type,description,reference_id,idempotency_key)
  values(v_sub.user_id,v_reward,'mission','Missão aprovada',v_sub.mission_id::text,'mission:'||v_sub.mission_id::text);
 end if;
 update public.mission_submissions set status=case when p_approve then 'approved' else 'rejected' end,
 reviewed_by=auth.uid(),reviewed_at=now(),review_note=coalesce(p_note,'') where id=p_submission_id;
end; $$;
revoke all on function public.admin_review_mission_submission(bigint,boolean,text) from public,anon;
grant execute on function public.admin_review_mission_submission(bigint,boolean,text) to authenticated;
