-- PIT PRÊMIOS: endurece validações e revisão transacional de saques.
-- STAGED ONLY. Não aplicar ao banco de produção sem autorização.

create or replace function public.request_withdrawal(p_points bigint,pix_key text,pix_key_type text)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_uid uuid := auth.uid(); v_id bigint;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if p_points is null or p_points < 10000 or p_points % 1000 <> 0 then
   raise exception 'invalid withdrawal amount';
 end if;
 if pix_key is null or length(trim(pix_key)) not between 3 and 200 then raise exception 'invalid PIX key'; end if;
 if pix_key_type is null or pix_key_type not in ('cpf','cnpj','email','phone','random') then raise exception 'invalid PIX key type'; end if;
 update public.profiles set points=points-p_points,updated_at=now()
 where id=v_uid and is_active=true and points>=p_points;
 if not found then raise exception 'insufficient points or inactive profile'; end if;
 insert into public.point_transactions(user_id,amount,transaction_type,description)
 values(v_uid,-p_points,'withdrawal','Solicitação de saque');
 insert into public.withdrawal_requests(user_id,points,pix_key,pix_key_type)
 values(v_uid,p_points,trim(pix_key),pix_key_type) returning id into v_id;
 return v_id;
end; $$;
revoke all on function public.request_withdrawal(bigint,text,text) from public,anon;
grant execute on function public.request_withdrawal(bigint,text,text) to authenticated;

create or replace function public.admin_review_withdrawal(p_request_id bigint,p_decision text,p_note text default null)
returns void language plpgsql security definer set search_path=public as $$
declare v_req public.withdrawal_requests%rowtype; v_note text;
begin
 if auth.uid() is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 if p_request_id is null then raise exception 'invalid request id'; end if;
 if p_decision is null or p_decision not in ('approved','rejected') then raise exception 'invalid decision'; end if;
 v_note:=left(coalesce(trim(p_note),''),1000);
 select * into v_req from public.withdrawal_requests where id=p_request_id for update;
 if not found then raise exception 'withdrawal not found'; end if;
 if v_req.status <> 'pending' then raise exception 'request already reviewed'; end if;
 if p_decision='rejected' then
   update public.profiles set points=points+v_req.points,updated_at=now() where id=v_req.user_id;
   if not found then raise exception 'profile missing; refund aborted'; end if;
   insert into public.point_transactions(user_id,amount,transaction_type,description,reference_id,created_by)
   values(v_req.user_id,v_req.points,'reversal','Estorno de saque rejeitado',v_req.id::text,auth.uid());
 end if;
 update public.withdrawal_requests set status=p_decision,reviewed_at=now(),reviewed_by=auth.uid(),admin_note=v_note
 where id=p_request_id and status='pending';
 if not found then raise exception 'request review race detected'; end if;
end; $$;
revoke all on function public.admin_review_withdrawal(bigint,text,text) from public,anon;
grant execute on function public.admin_review_withdrawal(bigint,text,text) to authenticated;
