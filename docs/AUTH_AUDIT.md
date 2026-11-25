# Auditoria de autenticação — etapa de inspeção

Status: revisão estática do frontend e migration de atribuição de indicação. Nenhuma alteração no Supabase live.

## Verificações
- Login: `signInWithPassword` via Supabase Auth.
- Cadastro: `signUp` e metadata `referrer_id`; a migration 0020 valida UUID, evita auto-indicação e verifica perfis ativos.
- Sessão inicial: `getSession()` e leitura do perfil `is_active`.
- Sessão renovada: `onAuthStateChange` e verificação de perfil ativo/admin.
- Administração: verificação via RPC `is_app_admin`, complementada por funções SQL protegidas nas migrations.

## Pontos a corrigir/validar
1. Fluxo de recuperação de senha não está implementado na interface.
2. Verificação de perfil/admin está duplicada entre inicialização e callback de sessão, podendo causar verificações concorrentes.
3. Erros de leitura do perfil/RPC devem ser tratados explicitamente como falha segura, sem liberar a sessão.
4. A configuração de redirect e confirmação de e-mail deve ser conferida no painel Supabase (não verificável apenas no código).
5. Não foi possível validar regras/configuração do projeto Supabase remoto; revisão estática não equivale a teste de segurança em produção.

## Limites desta etapa
- Não altera saldo, usuários, dados, nem banco.
- Não aplica migrations.
- Não afirma validação de configuração remota.
