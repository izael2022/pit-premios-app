-- PIT PRÊMIOS: estrutura de solicitações de saque.
-- Não execute automaticamente. Revisão/aplicação manual necessária.
create table if not exists public.withdrawal_requests (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete restrict,
  points bigint not null check (points >= 10000),
  pix_key text not null check (length(trim(pix_key)) between 3 and 200),
  pix_key_type text not null check (pix_key_type in ('cpf','cnpj','email','phone','random')),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id),
  admin_note text
);
create index if not exists withdrawal_requests_user_date on public.withdrawal_requests(user_id,created_at desc);
alter table public.withdrawal_requests enable row level security;
revoke all on public.withdrawal_requests from anon,authenticated;
-- Função transacional: valida saldo, debita, registra ledger e pedido.
create or replace function public.request_withdrawal(p_points bigint,pix_key text,pix_key_type text)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_uid uuid := auth.uid(); v_id bigint;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if p_points < 10000 then raise exception 'minimum withdrawal is 10000 points'; end if;
 if p_points % 1000 <> 0 then raise exception 'points must be in increments of 1000'; end if;
 if pix_key is null or length(trim(pix_key)) not between 3 and 200 then raise exception 'invalid PIX key'; end if;
 if pix_key_type not in ('cpf','cnpj','email','phone','random') then raise exception 'invalid PIX key type'; end if;
 update public.profiles set points=points-p_points,updated_at=now()
 where id=v_uid and points>=p_points;
 if not found then raise exception 'insufficient points'; end if;
 insert into public.point_transactions(user_id,amount,transaction_type,description)
 values(v_uid,-p_points,'withdrawal','Solicitação de saque');
 insert into public.withdrawal_requests(user_id,points,pix_key,pix_key_type)
 values(v_uid,p_points,trim(pix_key),pix_key_type) returning id into v_id;
 return v_id;
end; $$;
revoke all on function public.request_withdrawal(bigint,text,text) from public,anon;
grant execute on function public.request_withdrawal(bigint,text,text) to authenticated;
