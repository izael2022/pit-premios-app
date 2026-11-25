# Auditoria estática — missões e comprovações

## Escopo
Migrations 0012–0016 e componente src/modules/missions/Missions.jsx.

## Controles observados
- Missões têm limites de recompensa, título e período (0012/0013/0015).
- Resgate automático verifica usuário autenticado/ativo, missão ativa e janela de tempo, usa unique(mission_id,user_id) para impedir resgate duplicado, e registra saldo e ledger na mesma RPC (0012/0014).
- Resgate direto de missão manual é bloqueado pela versão revisada de claim_mission (0014).
- Submissão manual valida texto e disponibilidade da missão; unique(mission_id,user_id) evita submissões duplicadas (0014).
- Revisão administrativa verifica admin, bloqueia linha com FOR UPDATE, impede revisar status diferente de pending, limita nota e aprova/estorna status na mesma função (0016).
- Aprovação manual verifica a missão ainda ativa e dentro da janela, cria claim, credita perfil e ledger e marca submission como approved.

## Pontos de atenção / potenciais falhas de produto
1. **Reenvio após rejeição:** unique(mission_id,user_id) em mission_submissions impede nova submissão para a mesma missão. A UI mostra rejeitada, mas não oferece nova tentativa. Confirmar se regra desejada ou se precisa de fluxo de retry/reabertura.
2. **Missão expirada durante análise:** aprovação exige missão ainda ativa e dentro do período; pedidos pendentes podem ficar impossíveis de aprovar após expiração. Planejar regra explícita para submissões feitas antes do prazo.
3. **Conflito de recompensa:** revisar se a edição de reward_points após submissões pendentes pode alterar o valor que será creditado; a aprovação usa o valor atual da missão, não snapshot no envio.
4. **Auditoria de créditos:** verificar idempotency constraints efetivas e grants/RLS em staging; uniqueness da claim e transação são proteções, mas não comprovam o conjunto de políticas aplicado.
5. **UX de erro:** componente só apresenta erros textuais gerais; verificar tratamento de retry e erros de rede sem ressubmeter inadvertidamente.
6. **Admin note:** componente atual de revisão de comprovação envia nota vazia, embora RPC suporte nota; observação administrativa não está disponível no fluxo de UI analisado.

## Testes staging/local sugeridos
- Crédito automático uma vez e retry do mesmo claim.
- Dois claims concorrentes do mesmo usuário/mission.
- User inactive e mission inactive/future/expired.
- Submit manual válido, inválido, repetido.
- Admin comum versus admin ativo/inativo.
- Aprovar duas vezes ou concorrente: apenas uma aprovação e crédito.
- Rejeição: nenhum crédito e status rejeitado; confirmar regra de reenvio.
- Mission expira entre envio e revisão; decidir/testar comportamento.
- Alterar recompensa enquanto há submissions pending; confirmar política.
- Verificar saldo, ledger e claim/submission juntos em caso de falha, rollback.

## Limites
Análise estática de migrations/componentes. Nenhum teste SQL foi executado em staging. Nenhuma migração aplicada, e nenhum dado de produção alterado.
