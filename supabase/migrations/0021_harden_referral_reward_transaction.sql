-- PIT PRÊMIOS: reforço transacional/idempotente do processamento de indicações.
-- STAGED ONLY: não aplicar ao Supabase real sem autorização.
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
 v_key text;
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
   update public.referrals set status='rejected',qualification_note=trim(p_note) where id=p_referral_id and status='pending';
   if not found then raise exception 'referral review conflict'; end if;
   return;
 end if;

 if not exists(select 1 from public.profiles where id=v_ref.referrer_id and is_active=true) then raise exception 'referrer is inactive'; end if;
 if not exists(select 1 from public.profiles where id=v_ref.referred_id and is_active=true) then raise exception 'referred account is inactive'; end if;

 v_key := 'referral:'||p_referral_id::text;
 if exists(select 1 from public.point_transactions where user_id=v_ref.referrer_id and idempotency_key=v_key) then
   raise exception 'referral reward ledger entry already exists';
 end if;

 update public.profiles set points=points+p_reward_points,updated_at=now()
 where id=v_ref.referrer_id and is_active=true;
 if not found then raise exception 'referrer balance update failed'; end if;

 insert into public.point_transactions(user_id,amount,transaction_type,description,reference_id,idempotency_key,created_by)
 values(v_ref.referrer_id,p_reward_points,'referral','Recompensa por indicação qualificada',p_referral_id::text,v_key,v_admin);

 update public.referrals set status='qualified',qualified_at=now(),qualification_note=trim(p_note)
 where id=p_referral_id and status='pending';
 if not found then raise exception 'referral status update failed'; end if;
end; $$;
revoke all on function public.admin_review_referral(bigint,text,bigint,text) from public,anon;
grant execute on function public.admin_review_referral(bigint,text,bigint,text) to authenticated;
