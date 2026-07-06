# Velô Sprint - Configurador de Veículo Elétrico

Aplicação web em React para configuração e compra do veículo elétrico **Velô Sprint**.

## Sobre o Projeto

Uma SPA (Single Page Application) que permite:
- Personalizar cores, rodas e opcionais do veículo
- Calcular preços em tempo real
- Realizar pedidos com análise de crédito
- Consultar status de pedidos

**Especificações do Velô Sprint:** 450 km de autonomia | 0-100 km/h em 3.2s | 500 cv

---

## Stack Tecnológica

| Categoria | Tecnologias |
|-----------|-------------|
| **Frontend** | React 18, TypeScript, Vite, Tailwind CSS, shadcn/ui |
| **Estado** | Zustand (global), React Hook Form (formulários) |
| **Validação** | Zod |
| **Data Fetching** | TanStack Query |
| **Backend** | Supabase (PostgreSQL + Edge Functions) |

---

## Instalação

```bash
# Instalar dependências
yarn install

# Rodar em desenvolvimento
yarn dev
```

Acesse: `http://localhost:5173`

---

## Configuração do Supabase

### 1. Criar Projeto

1. Acesse [supabase.com](https://supabase.com) e crie uma conta
2. Clique em **New Project**
3. Escolha um nome e senha para o banco
4. Aguarde a criação (~2 minutos)

### 2. Variáveis de Ambiente

Crie o arquivo `.env` na raiz do projeto:

```env
VITE_SUPABASE_PROJECT_ID="seu_project_id"
VITE_SUPABASE_PUBLISHABLE_KEY="sua_chave_anon_publica"
VITE_SUPABASE_URL="https://seu_project_id.supabase.co"
```

> Encontre essas informações em: **Project Settings → API**

### 3. Deploy (banco + functions)

```bash
# Instalar CLI
yarn add supabase -D

# Login e vincular projeto
yarn supabase login
yarn supabase link --project-ref hntnfpmsjaaoehlxybin

# Aplicar migrações (cria tabelas e RLS)
yarn supabase db push

# Deploy das Edge Functions
yarn supabase functions deploy
```

Pronto! O banco e as functions estarão configurados.

---

## Ambientes Preview e Produção

O projeto usa **dois projetos Supabase**:

| Ambiente | Project ref | Uso |
|----------|-------------|-----|
| **Produção** | `hntnfpmsjaaoehlxybin` | Usuários reais, deploy Production na Vercel |
| **Preview** | `rbinxzqgwuvfzhdphjfy` | E2E no CI, deploy Preview na Vercel |

### Variáveis na Vercel

Configure por escopo em **Project Settings → Environment Variables**:

- **Production:** `VITE_SUPABASE_*` apontando para `hntnfpmsjaaoehlxybin`
- **Preview:** `VITE_SUPABASE_*` apontando para `rbinxzqgwuvfzhdphjfy`

Variáveis: `VITE_SUPABASE_URL`, `VITE_SUPABASE_PROJECT_ID`, `VITE_SUPABASE_PUBLISHABLE_KEY`.

> `VITE_*` são embutidas no bundle em tempo de build — cada ambiente precisa do seu próprio build.

### Pipeline de CD (`.github/workflows/cd.yml`)

```
Unit Tests → Supabase Preview → Deploy Vercel Preview → E2E → Supabase Prod → Deploy Production
```

1. **Supabase preview:** `db push --db-url` + `functions deploy --project-ref` (sem `supabase link`)
2. **Build preview:** `vercel pull --environment=preview` → `vercel build` → deploy preview
3. **E2E:** testes contra URL de preview + `DATABASE_URL_PREVIEW`
4. **Supabase prod:** migrações e functions no projeto de produção
5. **Deploy production:** `vercel pull --environment=production` → `vercel build --prod` → deploy prod

### Por que não usamos `vercel promote`?

O job original fazia `vercel promote` do deploy de preview para produção. Isso **reutiliza o mesmo artefato** gerado com variáveis `VITE_*` de **preview** — produção continuaria apontando para o Supabase de preview.

**Solução adotada:** após E2E passarem, um **build de produção dedicado** (`vercel pull --environment=production` + `vercel build --prod`) gera um bundle novo com credenciais de produção. Comportamento equivalente ao objetivo do promote, sem o risco de credenciais erradas no bundle.

### E2E local contra preview

Por padrão, `yarn playwright test` usa `.env` (geralmente produção). Para testar contra preview:

```bash
cp .env.test.example .env.test   # preencha com credenciais do preview
yarn test:e2e:preview
```

O script carrega `.env.test` e sobe o Vite em modo `test` com as variáveis de preview.

---

## Estrutura Principal

```
src/
├── pages/           # Páginas da aplicação
├── components/      # Componentes React
│   ├── configurator/   # Configurador do carro
│   ├── landing/        # Landing page
│   └── ui/             # Componentes shadcn/ui
├── store/           # Estado global (Zustand)
├── hooks/           # Hooks customizados
└── integrations/    # Cliente Supabase
```

---

## Rotas

| Rota | Descrição |
|------|-----------|
| `/` | Landing page |
| `/configure` | Configurador do veículo |
| `/order` | Checkout/Pedido |
| `/success` | Confirmação do pedido |
| `/lookup` | Consulta de pedidos |

---

## Modelo de Preços

- **Preço base:** R$ 40.000
- **Rodas Sport:** +R$ 2.000
- **Precision Park:** +R$ 5.500
- **Flux Capacitor:** +R$ 5.000
- **Financiamento:** 12x com juros de 2% a.m.

---

## Banco de Dados

**Tabela `orders`** — campos principais:
- `order_number` — Formato: VLO-XXXXXX
- `color`, `wheel_type`, `optionals` — Configuração
- `customer_name`, `customer_email`, `customer_cpf` — Cliente
- `payment_method`, `total_price` — Pagamento
- `status` — pending, approved, rejected, analysis

---

## Análise de Crédito

| Score | Resultado |
|-------|-----------|
| > 700 | Aprovado |
| 501-700 | Em análise |
| ≤ 500 | Reprovado |

*Se entrada ≥ 50% do total, aprova mesmo com score < 700*

---

## Fluxo Principal

```
Landing → Configurador → Checkout → Análise de Crédito → Confirmação
```

---

## Scripts

```bash
npm run dev      # Desenvolvimento
npm run build    # Build de produção
npm run lint     # Verificar código
```