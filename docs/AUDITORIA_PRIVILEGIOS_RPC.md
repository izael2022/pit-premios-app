# Auditoria de privilégios e RPCs SECURITY DEFINER — PIT PRÊMIOS

**Escopo:** análise estática das migrations da branch `reconstrucao-pit-premios`. Não foi executada contra o Supabase nem alterou dados.

## Controles encontrados
- As RPCs analisadas usam `SECURITY DEFINER` com `SET search_path=public`, reduzindo risco de resolução de objetos em schemas inesperados.
- As RPCs administrativas examinadas verificam `auth.uid()` e `public.is_app_admin()` (ou pelo menos `is_app_admin()`); esta última exige vínculo em `app_admins` e perfil ativo.
- As funções de operação/revisão revogam EXECUTE de `public,anon` e concedem a `authenticated`.
- As RPCs de saque, crédito de missão, revisão de indicação, revisão de saque e submissão/revisão manual usam validações de estado, locks ou restrições de idempotência conforme seus caminhos.

## Observações e riscos que merecem acompanhamento
1. **Grant a authenticated em RPCs administrativas:** o grant é amplo para usuários autenticados, mas a autorização é feita dentro da função. O padrão é consistente nas funções inspecionadas; os testes reais de impersonação/admin e perfis inativos ainda são necessários.
2. **Função de trigger `handle_new_user()`:** é SECURITY DEFINER e fixa search_path. Ela deve permanecer somente no contexto do trigger; recomenda-se explicitar REVOKE EXECUTE de PUBLIC/anon/authenticated se compatível com o ambiente e revisar o owner/trigger após aplicação.
3. **`register_referral`:** permite registrar uma indicação via RPC, mas valida autenticação, contas ativas, auto-indicação e a unicidade do indicado. A atribuição no trigger de signup também usa `ON CONFLICT DO NOTHING`; a constraint unique(referred_id) impede duplicação.
4. **Auditoria estrutural, não runtime:** a análise não confirma grants atuais do banco, owners, políticas instaladas, nem concorrência ou comportamento real de transações.

## Resultado
Não foi identificada, nas funções examinadas, uma chamada administrativa sem verificação de administrador ou um `search_path` inseguro. O principal próximo teste é confirmar em banco de teste os privilégios efetivos e negativas de acesso para anon, usuário comum, perfil inativo e admin.

**Proteção operacional:** nenhuma migration foi aplicada e nenhuma tabela, conta, saldo ou dado de produção foi modificado.
