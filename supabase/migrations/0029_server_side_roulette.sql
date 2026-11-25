-- PIT PRÊMIOS: Roleta segura server-side (STAGED ONLY; não executar no Supabase sem autorização).
-- Resultado, limite diário e crédito são transacionados pelo servidor.
create table if not exists public.roulette_prizes (
 id bigint generated always as identity primary key,
 points bigint not null check(points>=0),
 weight integer not null check(weight>0),
 is_active boolean not null default true
);
create table if not exists public.roulette_spins (
 id bigint generated always as identity primary key,
 user_id uuid not null references auth.users(id) on delete restrict,
 prize_points bigint not null,
 spun_at timestamptz not null default now(),
 unique(user_id, (date_trunc('day', spun_at at time zone 'UTC')))
);
alter table public.roulette_prizes enable row level security;
alter table public.roulette_spins enable row level security;
revoke all on public.roulette_prizes,public.roulette_spins from anon,authenticated;
-- Seed only if no prizes exist.
insert into public.roulette_prizes(points,weight)
select v.points,v.weight from (values (0::bigint,35),(50::bigint,30),(100::bigint,20),(250::bigint,10),(500::bigint,5)) v(points,weight)
where not exists(select 1 from public.roulette_prizes);

create or replace function public.spin_roulette()
returns table(spin_id bigint, prize_points bigint, spun_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare
 v_uid uuid:=auth.uid(); v_total bigint; v_pick bigint; v_acc bigint:=0;
 v_prize bigint; v_spin bigint; v_byte integer;
 r record;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if not exists(select 1 from public.profiles where id=v_uid and is_active=true) then raise exception 'inactive profile'; end if;
 -- Serializa tentativas por usuário para impedir spins concorrentes.
 perform pg_advisory_xact_lock(hashtext(v_uid::text));
 if exists(select 1 from public.roulette_spins where user_id=v_uid and spun_at >= date_trunc('day',now() at time zone 'UTC') at time zone 'UTC' and spun_at < (date_trunc('day',now() at time zone 'UTC')+interval '1 day') at time zone 'UTC') then
  raise exception 'daily spin limit reached';
 end if;
 select sum(weight) into v_total from public.roulette_prizes where is_active;
 if v_total is null or v_total<=0 then raise exception 'roulette unavailable'; end if;
 v_byte:=get_byte(gen_random_bytes(4),0);
 v_pick:=(v_byte::bigint*v_total)/256;
 for r in select points,weight from public.roulette_prizes where is_active order by id loop
  v_acc:=v_acc+r.weight;
  if v_pick<v_acc then v_prize:=r.points; exit; end if;
 end loop;
 insert into public.roulette_spins(user_id,prize_points) values(v_uid,v_prize) returning id,spun_at into v_spin,spun_at;
 if v_prize>0 then
  update public.profiles set points=points+v_prize,updated_at=now() where id=v_uid and is_active=true;
  if not found then raise exception 'active profile required'; end if;
  insert into public.point_transactions(user_id,amount,transaction_type,description,reference_id,idempotency_key)
  values(v_uid,v_prize,'reward','Prêmio da roleta',v_spin::text,'roulette:'||v_spin::text);
 end if;
 spin_id:=v_spin; prize_points:=v_prize; return next;
end; $$;
revoke all on function public.spin_roulette() from public,anon;
grant execute on function public.spin_roulette() to authenticated;
