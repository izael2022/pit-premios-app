# Auditoria final — Saques e conclusão da auditoria estática

**Escopo:** revisão de migrations e funções staged na branch `reconstrucao-pit-premios`. Não foi executada em banco real. Nenhuma alteração em produção.

## Saque — pontos fortes encontrados
- `request_withdrawal` exige auth UID, mínimo 10.000 pontos, incremento de 1.000, validação de chave PIX e debit somente quando saldo suficiente.
- O débito de profile, lançamento negativo e criação do pedido ocorrem na mesma função transacional.
- `admin_review_withdrawal` verifica admin, bloqueia a linha (`FOR UPDATE`) e só processa status pending; protege contra revisão concorrente/repetida.
- Rejeição devolve pontos e registra lançamento reversal.

## Riscos / pendências de segurança e funcionalidade
1. **Perfil ativo não verificado no saque:** `request_withdrawal` verifica UID e saldo, mas não confere `profiles.is_active`. Deve ser ajustado antes de implantação.
2. **Sem idempotency key no pedido/ledger de saque:** repetir a RPC pode gerar pedidos múltiplos, se houver saldo suficiente. Cada pedido é individual e debitado, mas falta proteção contra retry duplicado de cliente. Recomenda-se chave idempotente por solicitação, validada server-side.
3. **Ledger reversal sem chave idempotente:** a revisão do pedido bloqueia duplicidade via status/row lock; ainda assim, deve-se adicionar uma chave única por estorno e teste de integridade.
4. **Leitura de saques do usuário:** migrations analisadas revogam grants de tabela e não criam policy de SELECT própria. UI que depende de leitura direta não terá acesso; criar RPC de leitura filtrada pelo UID, caso necessário.
5. **Payout externo:** status approved não comprova PIX enviado. A plataforma deve separar aprovação, envio externo e confirmação, se esse processo for automatizado posteriormente.

## Conclusão
A revisão estática das migrations e RPCs cobertas nesta série está encerrada como **auditoria estática**, com os riscos acima registrados. Ela não equivale a certificação de segurança nem a testes runtime. Antes de ativar mudanças em produção, corrigir os riscos 1 e 2 e executar as suites em staging descartável.

## Próxima fase
A auditoria pode ser encerrada no branch de trabalho e os demais sistemas podem ser adicionados em etapas, preservando os riscos registrados como gate antes da implantação de funções financeiras.
