-- PIT PRÊMIOS: hardening das revisões de missões manuais.
-- STAGED ONLY: não aplicar ao Supabase live sem autorização.
-- Permite que uma submissão rejeitada seja reenviada; mantém bloqueio de duplicidade
-- para submissões pendentes/aprovadas e exige status rejeitado prévio para reutilizar.
create or replace function public.submit_mission(p_mission_id bigint,p_proof text)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_id bigint; v_sub public.mission_submissions%rowtype;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if not exists(select 1 from public.profiles where id=v_uid and is_active=true) then raise exception 'inactive profile'; end if;
 if p_proof is null or length(trim(p_proof)) not between 1 and 2000 then raise exception 'invalid proof'; end if;
 if not exists(select 1 from public.missions where id=p_mission_id and is_active=true and verification_mode='manual'
  and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>now())) then raise exception 'mission unavailable'; end if;
 select * into v_sub from public.mission_submissions where mission_id=p_mission_id and user_id=v_uid for update;
 if found then
   if v_sub.status<>'rejected' then raise exception 'submission already exists'; end if;
   update public.mission_submissions set proof_text=trim(p_proof),status='pending',
     reviewed_by=null,reviewed_at=null,review_note='',created_at=now()
   where id=v_sub.id returning id into v_id;
   return v_id;
 end if;
 insert into public.mission_submissions(mission_id,user_id,proof_text)
 values(p_mission_id,v_uid,trim(p_proof)) returning id into v_id;
 return v_id;
end; $$;

-- Lista administrativa paginada implicitamente por limite para evitar consultas gigantes.
create or replace function public.admin_list_mission_submissions()
returns table(id bigint,mission_id bigint,user_id uuid,proof_text text,status text,review_note text,created_at timestamptz,title text,reward_points bigint)
language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 return query select s.id,s.mission_id,s.user_id,s.proof_text,s.status,s.review_note,s.created_at,m.title,m.reward_points
 from public.mission_submissions s join public.missions m on m.id=s.mission_id
 order by s.created_at desc limit 500;
end; $$;
revoke all on function public.submit_mission(bigint,text) from public,anon;
grant execute on function public.submit_mission(bigint,text) to authenticated;
revoke all on function public.admin_list_mission_submissions() from public,anon;
grant execute on function public.admin_list_mission_submissions() to authenticated;
