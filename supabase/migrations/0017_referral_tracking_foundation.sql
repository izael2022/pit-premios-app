-- PIT PRÊMIOS: base de rastreamento de indicações.
-- STAGED ONLY: não aplicar no banco live sem autorização.
-- Recompensas não são creditadas nesta migration; regras/valores requerem configuração posterior.
create table if not exists public.referrals (
 id bigint generated always as identity primary key,
 referrer_id uuid not null references auth.users(id) on delete restrict,
 referred_id uuid not null references auth.users(id) on delete restrict,
 status text not null default 'pending' check(status in ('pending','qualified','rejected')),
 qualification_note text not null default '',
 created_at timestamptz not null default now(),
 qualified_at timestamptz,
 unique(referred_id),
 check(referrer_id<>referred_id)
);
create index if not exists referrals_referrer_created_idx on public.referrals(referrer_id,created_at desc);
alter table public.referrals enable row level security;
revoke all on public.referrals from anon,authenticated;
create policy referrals_read_involved on public.referrals for select to authenticated
 using(referrer_id=auth.uid() or referred_id=auth.uid());
grant select on public.referrals to authenticated;

create or replace function public.register_referral(p_referrer uuid)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_id bigint;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if v_uid=p_referrer then raise exception 'self referral not allowed'; end if;
 if not exists(select 1 from public.profiles where id=v_uid and is_active=true)
 or not exists(select 1 from public.profiles where id=p_referrer and is_active=true) then raise exception 'active accounts required'; end if;
 insert into public.referrals(referrer_id,referred_id,status)
 values(p_referrer,v_uid,'pending') returning id into v_id;
 return v_id;
end; $$;
revoke all on function public.register_referral(uuid) from public,anon;
grant execute on function public.register_referral(uuid) to authenticated;
