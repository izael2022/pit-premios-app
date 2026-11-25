-- PIT PRÊMIOS: qualificação/rejeição administrativa e crédito idempotente de indicação.
-- STAGED ONLY: não aplicar no Supabase live sem autorização.
-- O admin define o prêmio em pontos no momento da aprovação; não fixa valor comercial.
create or replace function public.admin_review_referral(
 p_referral_id bigint,
 p_decision text,
 p_reward_points bigint default 0,
 p_note text default ''
)
returns void language plpgsql security definer set search_path=public as $$
declare
 v_ref public.referrals%rowtype;
 v_admin uuid:=auth.uid();
begin
 if v_admin is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 if p_decision not in ('qualified','rejected') then raise exception 'invalid decision'; end if;
 if p_note is null or length(p_note)>1000 then raise exception 'invalid note'; end if;
 if p_decision='qualified' and (p_reward_points is null or p_reward_points<=0 or p_reward_points>1000000) then raise exception 'reward points must be between 1 and 1000000'; end if;
 if p_decision='rejected' and coalesce(p_reward_points,0)<>0 then raise exception 'rejection cannot award points'; end if;

 select * into v_ref from public.referrals where id=p_referral_id for update;
 if not found then raise exception 'referral not found'; end if;
 if v_ref.status<>'pending' then raise exception 'referral already reviewed'; end if;

 if p_decision='rejected' then
   update public.referrals set status='rejected',qualification_note=trim(p_note) where id=p_referral_id;
   return;
 end if;

 if not exists(select 1 from public.profiles where id=v_ref.referrer_id and is_active=true) then raise exception 'referrer is inactive'; end if;
 update public.profiles set points=points+p_reward_points,updated_at=now() where id=v_ref.referrer_id;
 insert into public.point_transactions(user_id,amount,transaction_type,description,reference_id,idempotency_key,created_by)
 values(v_ref.referrer_id,p_reward_points,'referral','Recompensa por indicação qualificada',p_referral_id::text,'referral:'||p_referral_id::text,v_admin);
 update public.referrals set status='qualified',qualified_at=now(),qualification_note=trim(p_note) where id=p_referral_id;
end; $$;

revoke all on function public.admin_review_referral(bigint,text,bigint,text) from public,anon;
grant execute on function public.admin_review_referral(bigint,text,bigint,text) to authenticated;
