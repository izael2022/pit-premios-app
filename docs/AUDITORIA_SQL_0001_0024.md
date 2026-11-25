# Auditoria técnica das migrations SQL 0001–0024

**Escopo:** leitura estática dos arquivos SQL na branch reconstrucao-pit-premios. Não foram executados SQL, testes de ataque, nem mudanças no banco Supabase. A leitura não substitui testes em staging.

## Controles observados
- Profiles: RLS habilitada, leitura por UID, inserção inicial com points=0; nenhuma política UPDATE de saldo na migration inicial.
- Ledger: RLS habilitada e escrita reservada às RPCs/serviços; política de leitura por usuário; trigger append-only em migration 0009.
- Saques: validação de mínimo (10.000), incremento, chave PIX, lock de perfil e limite de pedido pendente; índice parcial único em migration 0022. Revisão transacional e estorno com chave de idempotência.
- Missões: reivindicação única por missão/usuário, controle de datas e modo automático/manual, submissões com lock na revisão e reenvio apenas após rejeição.
- Indicações: proibição de autoindicação, unique referred_id, revisão com lock, verificação de atividade e ledger idempotente.
- Funções administrativas: maioria exige is_app_admin() e restringe EXECUTE para authenticated após revogar public/anon.
- Funções SECURITY DEFINER observadas usam set search_path=public; objetos de tabelas estão qualificados como public.*.

## Pontos que requerem testes de staging (não comprovados como vulnerabilidades)
1. **Policies/grants em todo o schema:** confirmar que nenhuma tabela tem grants de escrita excessivos ou policies inesperadas, incluindo as tabelas criadas/revisadas no conjunto 0001–0024.
2. **Bootstrap e gestão de admins:** validar procedimento manual para cadastrar o primeiro admin, bem como proteção contra mudanças no app_admins por clientes autenticados.
3. **Concorrência e idempotência:** testar, com duas sessões, resgates de missão, aprovação manual, revisão de saque/estorno e recompensa de indicação; verificar ledger e saldo sempre consistentes.
4. **Acesso a perfil inativo:** confirmar bloqueio de todas as RPCs de negócio e consultas permitidas quando is_active=false.
5. **Campos e limites:** validar tipos, valores nulos, limites, texto e parâmetros de todas as RPCs, inclusive chamadas fora da interface.
6. **Revisão de missões:** confirmar que uma submissão pendente não pode ser aprovada duas vezes e que o prêmio permanece consistente com a missão e seu período.
7. **Auditoria de grants efetivos:** executar inventário read-only de privileges para role anon/authenticated e ACLs de funções em staging, pois o arquivo de migrations sozinho não prova o estado efetivo do banco.

## Resultado
Não foi identificado, pela leitura estática isolada, motivo suficiente para aplicar alterações no banco live. O próximo passo seguro é preparar uma bateria de testes negativos/concorrência e um inventário de policies/grants em ambiente de staging. Nenhuma alteração em dados, saldos, usuários ou banco live foi feita.
