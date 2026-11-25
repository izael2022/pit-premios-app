-- PIT PRÊMIOS: limita saques pendentes e serializa solicitações por usuário.
-- STAGED ONLY; não aplicado ao banco live.
create or replace function public.request_withdrawal(p_points bigint,pix_key text,pix_key_type text)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_uid uuid := auth.uid(); v_id bigint; v_balance bigint;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if p_points is null or p_points < 10000 or p_points % 1000 <> 0 then raise exception 'invalid withdrawal amount'; end if;
 if pix_key is null or length(trim(pix_key)) not between 3 and 200 then raise exception 'invalid PIX key'; end if;
 if pix_key_type is null or pix_key_type not in ('cpf','cnpj','email','phone','random') then raise exception 'invalid PIX key type'; end if;

 -- Lock the profile row to serialize requests from this account.
 select points into v_balance from public.profiles
 where id=v_uid and is_active=true for update;
 if not found then raise exception 'inactive profile or profile missing'; end if;

 if exists (select 1 from public.withdrawal_requests where user_id=v_uid and status='pending') then
   raise exception 'pending withdrawal already exists';
 end if;
 if v_balance < p_points then raise exception 'insufficient points'; end if;

 update public.profiles set points=points-p_points,updated_at=now() where id=v_uid;
 insert into public.point_transactions(user_id,amount,transaction_type,description)
 values(v_uid,-p_points,'withdrawal','Solicitação de saque');
 insert into public.withdrawal_requests(user_id,points,pix_key,pix_key_type)
 values(v_uid,p_points,trim(pix_key),pix_key_type) returning id into v_id;
 return v_id;
end; $$;
revoke all on function public.request_withdrawal(bigint,text,text) from public,anon;
grant execute on function public.request_withdrawal(bigint,text,text) to authenticated;
