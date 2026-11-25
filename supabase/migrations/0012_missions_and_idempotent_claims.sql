-- PIT PRÊMIOS: base segura para missões e reivindicação idempotente.
-- STAGED ONLY. Não aplicado ao Supabase de produção.
create table if not exists public.missions (
 id bigint generated always as identity primary key,
 title text not null check (length(trim(title)) between 1 and 120),
 description text not null default '',
 reward_points bigint not null check (reward_points > 0 and reward_points <= 1000000),
 is_active boolean not null default false,
 starts_at timestamptz,
 ends_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check (ends_at is null or starts_at is null or ends_at > starts_at)
);
create table if not exists public.mission_claims (
 id bigint generated always as identity primary key,
 mission_id bigint not null references public.missions(id) on delete restrict,
 user_id uuid not null references auth.users(id) on delete restrict,
 claimed_at timestamptz not null default now(),
 unique(mission_id,user_id)
);
alter table public.missions enable row level security;
alter table public.mission_claims enable row level security;
revoke all on public.missions,public.mission_claims from anon,authenticated;
create policy missions_active_read on public.missions for select to authenticated using (is_active=true);
create policy mission_claims_read_own on public.mission_claims for select to authenticated using (user_id=auth.uid());
grant select on public.missions,public.mission_claims to authenticated;

create or replace function public.claim_mission(p_mission_id bigint)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_reward bigint; v_claim_id bigint;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if not exists(select 1 from public.profiles where id=v_uid and is_active=true) then raise exception 'inactive profile'; end if;
 select reward_points into v_reward from public.missions
 where id=p_mission_id and is_active=true
 and (starts_at is null or starts_at<=now())
 and (ends_at is null or ends_at>now())
 for share;
 if not found then raise exception 'mission unavailable'; end if;

 insert into public.mission_claims(mission_id,user_id)
 values(p_mission_id,v_uid) returning id into v_claim_id;

 update public.profiles set points=points+v_reward,updated_at=now()
 where id=v_uid and is_active=true;
 if not found then raise exception 'active profile required'; end if;

 insert into public.point_transactions(user_id,amount,transaction_type,description,reference_id,idempotency_key)
 values(v_uid,v_reward,'mission','Recompensa de missão',p_mission_id::text,'mission:'||p_mission_id::text);

 return v_claim_id;
end; $$;
revoke all on function public.claim_mission(bigint) from public,anon;
grant execute on function public.claim_mission(bigint) to authenticated;

-- Escrita de configurações de missões reservada às funções administrativas futuras.
