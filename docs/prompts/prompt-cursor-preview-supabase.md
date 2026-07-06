# TAREFA: Isolar ambiente de Preview do ambiente de Produção (Supabase + Vercel + CI/CD)

## CONTEXTO
Este projeto usa:
- Supabase como backend (banco, RLS policies, Edge Functions em `supabase/functions`, migrações em `supabase/migrations`)
- Vercel para deploy (Production e Preview)
- GitHub Actions (`.github/workflows/cd.yml`) rodando: testes unitários → deploy preview → testes E2E (Playwright) contra a URL de preview → promote para produção

## PROBLEMA ATUAL
Existe apenas UM projeto Supabase. As variáveis `VITE_SUPABASE_URL`, `VITE_SUPABASE_PROJECT_ID` e `VITE_SUPABASE_PUBLISHABLE_KEY` são idênticas em Preview e Production na Vercel. Isso significa que os testes E2E rodam contra o banco de PRODUÇÃO, podendo poluir ou até apagar dados reais de clientes.

## OBJETIVO
1. Ter dois projetos Supabase distintos: um de produção (o atual) e um novo de preview.
2. Migrações e Edge Functions do diretório do projeto sincronizadas nos dois ambientes Supabase.
3. RLS policies idênticas entre os dois projetos.
4. Vercel configurada para que:
   - Ambiente **Production** use as `VITE_SUPABASE_*` de produção
   - Ambiente **Preview** use as `VITE_SUPABASE_*` de preview
5. O pipeline de CD (`.github/workflows/cd.yml`) ajustado para que:
   - O build de Preview use as variáveis de preview
   - Os testes E2E rodem contra o banco de preview
   - O **promote** para produção resulte em um build que efetivamente fale com o Supabase de produção (investigar se `vercel promote` reaproveita o build já gerado com variáveis de preview embutidas, já que `VITE_*` são compiladas em tempo de build — isso pode exigir gerar um novo build específico para produção em vez de promover o build de preview "as is". Avaliar as opções e escolher a mais adequada, documentando o motivo).
6. Nenhuma secret ou variável sensível deve ser commitada no repositório.

## CRITÉRIOS DE ACEITAÇÃO
- Dois projetos Supabase distintos (preview e produção) existem e estão configurados.
- Um pedido/dado criado durante os testes E2E não aparece no banco de produção.
- Após o promote, produção lê/escreve no banco de produção — não no de preview.
- Testes E2E continuam passando no pipeline.
- Migrações e Edge Functions sincronizadas entre os dois projetos.
- Nenhuma secret commitada no repositório.

## COMO QUERO QUE VOCÊ TRABALHE (MUITO IMPORTANTE)

**NÃO execute nenhuma ação, comando, criação de recurso, edição de arquivo de workflow, ou alteração de configuração antes de eu confirmar explicitamente o plano.**

Siga esta ordem:

### Etapa 1 — Diagnóstico
Analise o repositório atual: leia `.github/workflows/cd.yml`, `supabase/migrations`, `supabase/functions`, arquivos de configuração da Vercel (`vercel.json` se existir) e o `README`. Resuma o que encontrou.

### Etapa 2 — Perguntas
Antes de propor o plano final, **liste todas as informações que faltam ou que você precisa que eu confirme**, por exemplo (adapte conforme o que encontrar no código):
- Nome/slug que devo usar para o novo projeto Supabase de preview
- Se eu já tenho acesso/token do Supabase CLI configurado, ou se você deve me guiar para gerar um
- Qual é o `--scope` e token da Vercel a usar (ou se devo fornecer)
- Se as secrets do GitHub Actions (ex: `SUPABASE_ACCESS_TOKEN`, `VERCEL_TOKEN`) já existem ou precisam ser criadas, e onde
- Se há dados/seed que precisam ser replicados no banco de preview além das migrações
- Se existe alguma Edge Function com segredos próprios (ex: chaves de API externas) que precisam ser configurados separadamente no projeto de preview
- Qualquer outra lacuna que você identificar ao ler o código

Aguarde minhas respostas antes de prosseguir.

### Etapa 3 — Plano detalhado
Com base no diagnóstico e nas minhas respostas, monte um plano passo a passo cobrindo:
1. Provisionamento do projeto Supabase de preview (via CLI, sequência de comandos, cuidado com `--project-ref`)
2. Deploy das migrações e Edge Functions no novo projeto
3. Conferência das RLS policies
4. Configuração das variáveis de ambiente na Vercel (Production vs Preview)
5. Ajuste do workflow `cd.yml` para o build de preview e para o fluxo de promote, com a alternativa escolhida (e por quê) para resolver o problema do `VITE_*` embutido no bundle
6. Validação do fluxo E2E, dashboard e checklist final dos critérios de aceitação

Apresente o plano de forma clara, em passos numerados, indicando **quais comandos serão rodados, quais arquivos serão alterados e quais recursos externos serão criados**.

### Etapa 4 — Confirmação
Pergunte explicitamente: **"Posso prosseguir com a execução deste plano?"** e só comece a executar depois que eu responder afirmativamente. Se eu pedir ajustes, revise o plano e pergunte novamente antes de agir.

## RESTRIÇÕES GERAIS
- Nunca commite tokens, chaves ou secrets no código-fonte.
- Toda credencial sensível deve ir em GitHub Secrets / variáveis de ambiente da Vercel, nunca em arquivos versionados.
- Prefira reutilizar os scripts já documentados no README (`yarn supabase link`, `yarn supabase db push`, `yarn supabase functions deploy`) em vez de recriar tabelas manualmente pela UI do Supabase.