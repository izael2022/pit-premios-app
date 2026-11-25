-- PIT PRÊMIOS: proteção adicional para saque pendente e estorno.
-- STAGED ONLY: não aplicar no Supabase de produção sem autorização explícita.
-- O índice impede dois pedidos pendentes mesmo se algum caminho futuro não usar o lock do perfil.
create unique index if not exists withdrawal_one_pending_per_user
on public.withdrawal_requests(user_id)
where status='pending';

create or replace function public.admin_review_withdrawal(
 p_request_id bigint,
 p_decision text,
 p_note text default null
)
returns void language plpgsql security definer set search_path=public as $$
declare
 v_req public.withdrawal_requests%rowtype;
 v_admin uuid:=auth.uid();
 v_note text;
 v_key text;
begin
 if v_admin is null or not public.is_app_admin() then raise exception 'admin access required'; end if;
 if p_request_id is null then raise exception 'invalid request id'; end if;
 if p_decision is null or p_decision not in ('approved','rejected') then raise exception 'invalid decision'; end if;
 if p_note is not null and length(p_note)>1000 then raise exception 'note too long'; end if;
 v_note:=left(coalesce(trim(p_note),''),1000);

 select * into v_req from public.withdrawal_requests where id=p_request_id for update;
 if not found then raise exception 'withdrawal not found'; end if;
 if v_req.status<>'pending' then raise exception 'request already reviewed'; end if;

 if p_decision='rejected' then
   if not exists(select 1 from public.profiles where id=v_req.user_id) then raise exception 'profile missing; refund aborted'; end if;
   v_key:='withdrawal-refund:'||v_req.id::text;
   if exists(select 1 from public.point_transactions where user_id=v_req.user_id and idempotency_key=v_key) then
     raise exception 'refund ledger entry already exists';
   end if;
   update public.profiles set points=points+v_req.points,updated_at=now() where id=v_req.user_id;
   if not found then raise exception 'refund failed'; end if;
   insert into public.point_transactions(user_id,amount,transaction_type,description,reference_id,idempotency_key,created_by)
   values(v_req.user_id,v_req.points,'reversal','Estorno de saque rejeitado',v_req.id::text,v_key,v_admin);
 end if;

 update public.withdrawal_requests
 set status=p_decision,reviewed_at=now(),reviewed_by=v_admin,admin_note=v_note
 where id=p_request_id and status='pending';
 if not found then raise exception 'request review race detected'; end if;
end; $$;
revoke all on function public.admin_review_withdrawal(bigint,text,text) from public,anon;
grant execute on function public.admin_review_withdrawal(bigint,text,text) to authenticated;
