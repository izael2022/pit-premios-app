-- PIT PRÊMIOS: estrutura inicial de perfil e saldo.
-- Esta migração NÃO foi executada no Supabase; revisar e executar apenas com autorização.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  points bigint not null default 0 check (points >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Usuários autenticados podem visualizar apenas o próprio perfil.
create policy "profiles_select_own"
on public.profiles for select
to authenticated
using (auth.uid() = id);

-- Permitir inserção somente no próprio id; saldo sempre inicial zero.
create policy "profiles_insert_own"
on public.profiles for insert
to authenticated
with check (auth.uid() = id and points = 0);

-- Não criar policy de UPDATE para pontos: mudanças de saldo devem ser feitas
-- por funções/serviços autorizados, com trilha de transações.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, points)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', ''), 0)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();
