-- PIT PRÊMIOS: Baú diário seguro (STAGED ONLY; não executar no banco live sem autorização).
create table if not exists public.daily_chest_openings(
 id bigint generated always as identity primary key,
 user_id uuid not null references auth.users(id) on delete restrict,
 prize_points bigint not null check(prize_points>=0),
 opened_at timestamptz not null default now()
);
alter table public.daily_chest_openings enable row level security;
revoke all on public.daily_chest_openings from anon,authenticated;

create or replace function public.open_daily_chest()
returns table(opening_id bigint, prize_points bigint, opened_at timestamptz, openings_today integer)
language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_count integer; v_prize bigint; v_id bigint; v_at timestamptz; v_roll numeric;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if not exists(select 1 from public.profiles where id=v_uid and is_active=true) then raise exception 'inactive profile'; end if;
 perform pg_advisory_xact_lock(hashtext(v_uid::text));
 select count(*) into v_count from public.daily_chest_openings
 where user_id=v_uid and opened_at >= date_trunc('day',now() at time zone 'UTC') at time zone 'UTC'
 and opened_at < (date_trunc('day',now() at time zone 'UTC')+interval '1 day') at time zone 'UTC';
 if v_count>=3 then raise exception 'daily chest limit reached'; end if;
 v_roll:=random();
 v_prize:=case when v_roll<0.40 then 0 when v_roll<0.70 then 50 when v_roll<0.90 then 100 when v_roll<0.98 then 250 else 500 end;
 insert into public.daily_chest_openings(user_id,prize_points) values(v_uid,v_prize) returning id,opened_at into v_id,v_at;
 if v_prize>0 then
  update public.profiles set points=points+v_prize,updated_at=now() where id=v_uid and is_active=true;
  if not found then raise exception 'active profile required'; end if;
  insert into public.point_transactions(user_id,amount,transaction_type,description,reference_id,idempotency_key)
  values(v_uid,v_prize,'reward','Prêmio do Baú Diário',v_id::text,'daily_chest:'||v_id::text);
 end if;
 opening_id:=v_id; prize_points:=v_prize; opened_at:=v_at; openings_today:=v_count+1; return next;
end; $$;
revoke all on function public.open_daily_chest() from public,anon;
grant execute on function public.open_daily_chest() to authenticated;
