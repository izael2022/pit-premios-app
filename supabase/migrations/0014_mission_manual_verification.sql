-- PIT PRÊMIOS: verificação manual de missões e aprovação transacional.
-- STAGED ONLY: não aplicar ao Supabase de produção sem autorização.
alter table public.missions
 add column if not exists verification_mode text not null default 'automatic'
 check (verification_mode in ('automatic','manual'));

create table if not exists public.mission_submissions (
 id bigint generated always as identity primary key,
 mission_id bigint not null references public.missions(id) on delete restrict,
 user_id uuid not null references auth.users(id) on delete restrict,
 proof_text text not null check(length(trim(proof_text)) between 1 and 2000),
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 reviewed_by uuid references auth.users(id),
 reviewed_at timestamptz,
 review_note text not null default '',
 created_at timestamptz not null default now(),
 unique(mission_id,user_id)
);
alter table public.mission_submissions enable row level security;
revoke all on public.mission_submissions from anon,authenticated;
create policy mission_submissions_read_own on public.mission_submissions
 for select to authenticated using(user_id=auth.uid());
grant select on public.mission_submissions to authenticated;

create or replace function public.submit_mission(p_mission_id bigint,p_proof text)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_id bigint;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if not exists(select 1 from public.profiles where id=v_uid and is_active=true) then raise exception 'inactive profile'; end if;
 if p_proof is null or length(trim(p_proof)) not between 1 and 2000 then raise exception 'invalid proof'; end if;
 if not exists(select 1 from public.missions where id=p_mission_id and is_active=true and verification_mode='manual'
 and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>now())) then raise exception 'mission unavailable'; end if;
 insert into public.mission_submissions(mission_id,user_id,proof_text)
 values(p_mission_id,v_uid,trim(p_proof)) returning id into v_id;
 return v_id;
end; $$;

-- Para missões manuais, claim_mission bloqueia o resgate direto.
create or replace function public.claim_mission(p_mission_id bigint)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_reward bigint; v_claim_id bigint;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if not exists(select 1 from public.profiles where id=v_uid and is_active=true) then raise exception 'inactive profile'; end if;
 select reward_points into v_reward from public.missions
 where id=p_mission_id and is_active=true and verification_mode='automatic'
 and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>now()) for share;
 if not found then raise exception 'mission unavailable or requires review'; end if;
 insert into public.mission_claims(mission_id,user_id) values(p_mission_id,v_uid) returning id into v_claim_id;
 update public.profiles set points=points+v_reward,updated_at=now() where id=v_uid and is_active=true;
 if not found then raise exception 'active profile required'; end if;
 insert into public.point_transactions(user_id,amount,transaction_type,description,reference_id,idempotency_key)
 values(v_uid,v_reward,'mission','Recompensa de missão',p_mission_id::text,'mission:'||p_mission_id::text);
 return v_claim_id;
end; $$;

create or replace function public.admin_review_mission_submission(p_submission_id bigint,p_approve boolean,p_note text default '')
returns void language plpgsql security definer set search_path=public as $$
declare v_sub public.mission_submissions%rowtype; v_reward bigint;
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
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

revoke all on function public.submit_mission(bigint,text) from public,anon;
revoke all on function public.claim_mission(bigint) from public,anon;
revoke all on function public.admin_review_mission_submission(bigint,boolean,text) from public,anon;
grant execute on function public.submit_mission(bigint,text) to authenticated;
grant execute on function public.claim_mission(bigint) to authenticated;
grant execute on function public.admin_review_mission_submission(bigint,boolean,text) to authenticated;
