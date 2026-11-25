# Auditoria de autorização dos módulos — PIT PRÊMIOS

**Escopo:** revisão estática dos componentes React e migrations de proteção disponíveis na branch reconstrucao-pit-premios. Não foi realizado teste remoto no Supabase nem alteração de banco.

## Observações dos componentes
- Wallet: leitura de perfil/ledger filtrada pelo usuário e pedido de saque via RPC request_withdrawal. A segurança efetiva depende da RPC e RLS.
- Missions: consulta de missões ativas e registros do próprio usuário; ações claim_mission e submit_mission via RPC. Dependem das verificações server-side.
- Invites: consulta filtrada por referrer_id do usuário. RLS deve garantir que esse filtro não possa ser contornado.
- Admin: interface consulta is_app_admin e usa RPCs admin_*. A autorização na interface é apenas UX; a proteção real deve estar nas RPCs e políticas do banco.
- App: valida perfil ativo e consulta is_app_admin. A validação client-side não substitui RLS e validação nas funções.

## Migrations revisadas
- 0025: impede que administrador altere o próprio estado e protege outros perfis administrativos.
- 0026: protege RPCs de listagem e ativação de missões com is_app_admin.
- 0027: relatório de integridade de pontos é somente leitura e exige is_app_admin.

## Limitações / próximos itens
1. Revisar todas as RPCs, grants e políticas RLS (incluindo migrations 0001–0024) por operação e tabela.
2. Confirmar que RPCs de saque, resgate de missão, recompensa manual, indicação e gestão de usuário validam auth.uid(), estado ativo e autorização administrativa quando aplicável.
3. Fazer testes negativos em ambiente de teste (usuário A tentar ler/alterar usuário B; usuário comum tentar executar RPC administrativa; usuário desativado tentar operações).
4. Não aplicar alterações ao Supabase live sem autorização explícita.

