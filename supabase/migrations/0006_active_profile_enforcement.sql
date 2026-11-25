-- PIT PRÊMIOS: enforcement de perfis ativos para RPCs existentes.
-- STAGED ONLY: não aplicar ao Supabase sem autorização explícita.
-- Protege operações transacionais existentes e impede admins desativados de exercer funções administrativas.

create or replace function public.is_app_admin()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(
   select 1 from public.app_admins a
   join public.profiles p on p.id=a.user_id
   where a.user_id=auth.uid() and p.is_active=true
 );
$$;
revoke all on function public.is_app_admin() from public,anon;
grant execute on function public.is_app_admin() to authenticated;

create or replace function public.request_withdrawal(p_points bigint,pix_key text,pix_key_type text)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_uid uuid := auth.uid(); v_id bigint; v_active boolean;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 select is_active into v_active from public.profiles where id=v_uid;
 if coalesce(v_active,false) is not true then raise exception 'profile inactive'; end if;
 if p_points < 10000 then raise exception 'minimum withdrawal is 10000 points'; end if;
 if p_points % 1000 <> 0 then raise exception 'points must be in increments of 1000'; end if;
 if pix_key is null or length(trim(pix_key)) not between 3 and 200 then raise exception 'invalid PIX key'; end if;
 if pix_key_type not in ('cpf','cnpj','email','phone','random') then raise exception 'invalid PIX key type'; end if;
 update public.profiles set points=points-p_points,updated_at=now()
 where id=v_uid and is_active=true and points>=p_points;
 if not found then raise exception 'insufficient points or inactive profile'; end if;
 insert into public.point_transactions(user_id,amount,transaction_type,description)
 values(v_uid,-p_points,'withdrawal','Solicitação de saque');
 insert into public.withdrawal_requests(user_id,points,pix_key,pix_key_type)
 values(v_uid,p_points,trim(pix_key),pix_key_type) returning id into v_id;
 return v_id;
end; $$;
revoke all on function public.request_withdrawal(bigint,text,text) from public,anon;
grant execute on function public.request_withdrawal(bigint,text,text) to authenticated;

-- RLS de perfil ativo: leitura do perfil próprio só enquanto ativo.
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles for select to authenticated
using (auth.uid()=id and is_active=true);

-- Segurança adicional para listagem/admin de saque: a função is_app_admin já exige perfil ativo.
