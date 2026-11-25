-- PIT PRÊMIOS: controle administrativo de solicitações de saque.
-- Staged only; requires review and explicit deployment authorization.
create table if not exists public.app_admins (
  user_id uuid primary key references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  granted_by uuid references auth.users(id)
);
alter table public.app_admins enable row level security;
revoke all on public.app_admins from public, anon, authenticated;

create or replace function public.is_app_admin()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.app_admins where user_id=auth.uid());
$$;
revoke all on function public.is_app_admin() from public,anon;
grant execute on function public.is_app_admin() to authenticated;

create or replace function public.admin_list_withdrawals()
returns table(id bigint,user_id uuid,display_name text,points bigint,pix_key text,pix_key_type text,status text,created_at timestamptz,reviewed_at timestamptz,admin_note text)
language plpgsql security definer set search_path=public as $$
begin
 if not public.is_app_admin() then raise exception 'admin access required'; end if;
 return query select w.id,w.user_id,p.display_name,w.points,w.pix_key,w.pix_key_type,w.status,w.created_at,w.reviewed_at,w.admin_note
 from public.withdrawal_requests w left join public.profiles p on p.id=w.user_id
 order by w.created_at desc limit 500;
end; $$;
revoke all on function public.admin_list_withdrawals() from public,anon;
grant execute on function public.admin_list_withdrawals() to authenticated;

create or replace function public.admin_review_withdrawal(p_request_id bigint,p_decision text,p_note text default null)
returns void language plpgsql security definer set search_path=public as $$
declare v_req public.withdrawal_requests%rowtype;
begin
 if not public.is_app_admin() then raise exception 'admin access required'; end if;
 if p_decision not in ('approved','rejected') then raise exception 'invalid decision'; end if;
 select * into v_req from public.withdrawal_requests where id=p_request_id for update;
 if not found then raise exception 'withdrawal not found'; end if;
 if v_req.status <> 'pending' then raise exception 'request already reviewed'; end if;
 if p_decision='rejected' then
   update public.profiles set points=points+v_req.points,updated_at=now() where id=v_req.user_id;
   insert into public.point_transactions(user_id,amount,transaction_type,description,reference_id,created_by)
   values(v_req.user_id,v_req.points,'reversal','Estorno de saque rejeitado',v_req.id::text,auth.uid());
 end if;
 update public.withdrawal_requests set status=p_decision,reviewed_at=now(),reviewed_by=auth.uid(),admin_note=left(coalesce(p_note,''),1000)
 where id=p_request_id;
end; $$;
revoke all on function public.admin_review_withdrawal(bigint,text,text) from public,anon;
grant execute on function public.admin_review_withdrawal(bigint,text,text) to authenticated;

-- Admin bootstrap deve ser feito manualmente, após identificar o UID correto do proprietário.
