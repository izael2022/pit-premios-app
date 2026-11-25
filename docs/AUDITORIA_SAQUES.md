# Auditoria do fluxo de saques — PIT PRÊMIOS

## Código revisado
Migrations 0003 (withdrawal_requests) e 0006 (active profile enforcement).

## Controles observados
- Mínimo de 10.000 pontos.
- Valor precisa ser múltiplo de 1.000.
- Chave PIX obrigatória (3 a 200 caracteres) e tipo permitido (cpf, cnpj, email, phone, random).
- Perfil precisa estar ativo e autenticado na versão 0006.
- Débito é condicional ao saldo suficiente, com verificação de `FOUND`.
- A função insere registro no ledger e pedido de saque após o débito; as etapas estão na mesma função transacional.
- Grants EXECUTE limitados a authenticated; anon/public revogados.
- RLS e grants da tabela de pedidos bloqueiam acesso direto de anon/authenticated.

## Pontos de atenção
1. No conjunto de migrations revisado, não há idempotency key no pedido de saque; reenvio após timeout deve ser investigado em ambiente de teste e pode gerar pedidos separados se saldo permitir.
2. A migration 0003 não verifica perfil ativo; o enforcement aparece na migration 0006. Verificar que a versão final aplicada inclui 0006.
3. Não localizei, no escopo acessível desta branch, a migration completa do fluxo administrativo de aprovação/rejeição; o teste deste documento não assume que esse fluxo está coberto.
4. A validação de concorrência deve testar duas solicitações simultâneas com saldo suficiente para somente uma, em ambiente isolado.
5. Não testei PIX real, aprovação administrativa, nem atualizei banco.

## Casos de teste recomendados em staging/local
- Rejeitar saque abaixo de 10.000.
- Rejeitar valor fora do múltiplo de 1.000.
- Rejeitar perfil inativo ou sessão ausente.
- Rejeitar chave PIX vazia/inválida ou tipo inválido.
- Com saldo insuficiente, não debitar nem criar pedido/ledger.
- Para operação válida, verificar débito, pedido e ledger negativo como um conjunto atômico.
- Simular repetição do mesmo request e concorrência, verificando duplicidade e consistência.

## Segurança
Somente local/staging descartável. Não execute contra produção. Nenhuma migration foi aplicada nesta auditoria.
