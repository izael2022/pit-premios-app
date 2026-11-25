-- PIT PRÊMIOS: atribuição de indicação no momento do cadastro.
-- STAGED ONLY: não executar no Supabase live sem autorização.
-- Captura referrer_id de auth metadata, valida UUID, atividade e auto-indicação.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_referrer uuid;
  v_raw text;
begin
  insert into public.profiles (id, display_name, points)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', ''), 0)
  on conflict (id) do nothing;

  v_raw := new.raw_user_meta_data->>'referrer_id';
  if v_raw is not null
     and v_raw ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    v_referrer := v_raw::uuid;
    if v_referrer <> new.id
       and exists (select 1 from public.profiles where id = v_referrer and is_active = true)
       and exists (select 1 from public.profiles where id = new.id and is_active = true) then
      insert into public.referrals (referrer_id, referred_id, status)
      values (v_referrer, new.id, 'pending')
      on conflict (referred_id) do nothing;
    end if;
  end if;
  return new;
end;
$$;
