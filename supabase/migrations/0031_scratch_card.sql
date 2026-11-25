-- PIT PRÊMIOS: Raspadinha diária (STAGED ONLY; não aplicar ao banco live sem autorização).
create table if not exists public.scratch_card_plays(
 id bigint generated always as identity primary key,
 user_id uuid not null references auth.users(id) on delete restrict,
 prize_points bigint not null check(prize_points>=0),
 played_at timestamptz not null default now()
);
alter table public.scratch_card_plays enable row level security;
revoke all on public.scratch_card_plays from anon,authenticated;

create or replace function public.play_scratch_card()
returns table(play_id bigint, prize_points bigint, played_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_prize bigint; v_id bigint; v_at timestamptz; v_roll numeric;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if not exists(select 1 from public.profiles where id=v_uid and is_active=true) then raise exception 'inactive profile'; end if;
 perform pg_advisory_xact_lock(hashtext(v_uid::text));
 if exists(select 1 from public.scratch_card_plays where user_id=v_uid and played_at >= (date_trunc('day',now() at time zone 'UTC')) at time zone 'UTC' and played_at < (date_trunc('day',now() at time zone 'UTC')+interval '1 day') at time zone 'UTC') then
  raise exception 'daily scratch card limit reached';
 end if;
 v_roll:=random();
 v_prize:=case when v_roll<0.50 then 0 when v_roll<0.80 then 50 when v_roll<0.95 then 100 when v_roll<0.99 then 250 else 500 end;
 insert into public.scratch_card_plays(user_id,prize_points) values(v_uid,v_prize) returning id,played_at into v_id,v_at;
 if v_prize>0 then
  update public.profiles set points=points+v_prize,updated_at=now() where id=v_uid and is_active=true;
  if not found then raise exception 'active profile required'; end if;
  insert into public.point_transactions(user_id,amount,transaction_type,description,reference_id,idempotency_key)
  values(v_uid,v_prize,'reward','Prêmio da Raspadinha',v_id::text,'scratch_card:'||v_id::text);
 end if;
 play_id:=v_id; prize_points:=v_prize; played_at:=v_at; return next;
end; $$;
revoke all on function public.play_scratch_card() from public,anon;
grant execute on function public.play_scratch_card() to authenticated;
