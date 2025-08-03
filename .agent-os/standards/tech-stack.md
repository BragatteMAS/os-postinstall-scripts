# Tech Stack

## Context

Global tech stack defaults for Agent OS projects, overridable in project-specific `.agent-os/product/tech-stack.md`.

## Default Stack (Modern Applications)

### Core Technologies
- **Languages**: TypeScript (primary), Python (ML/Analytics), Rust (performance-critical)
- **Runtime**: Bun (preferred) or Node.js 22 LTS
- **Package Manager**: pnpm > yarn > npm

### Backend
- **API Framework**: FastAPI (Python) or Bun + Elysia + tRPC (TypeScript)
- **Database**: PostgreSQL 17+ with Drizzle ORM
- **Real-time**: Supabase or Convex (experimental)
- **Validation**: Zod for schema validation

### Frontend
- **Framework**: Remix + React (SSR by default)
- **Styling**: TailwindCSS 4.0+
- **State Management**: Context API or Zustand
- **Data Visualization**: Observable Plot (scientific) or D3.js (custom)
- **Icons**: Lucide React components

### Infrastructure
- **Hosting**: Vercel, Railway, or Fly.io
- **Database**: Supabase (prototypes) or PostgreSQL managed
- **Storage**: Supabase Storage or S3-compatible
- **CDN**: Automatic with hosting platform

### Development (Essenciais)
- **Type Safety**: End-to-end with tRPC or typed API clients
- **Linting**: ESLint + Prettier (desenvolvimento local apenas)
- **Documentation**: Markdown + Observable notebooks

### ⚠️ Opcional - Implementar APENAS se requisitado em STORIES.md

#### Testing
- **E2E Testing (Primeira opção)**: Playwright
  - ✅ Integração com MCP disponível
  - ✅ Testes visuais e funcionais completos
  - ✅ Automação de browser real
- **Unit/Integration**: Vitest + Testing Library
  - Para testes isolados de componentes
  - Quando E2E for excessivo
- **Abordagem**: Testing Trophy (priorizar integração sobre unit)
- **Quando usar**: Apenas quando explicitamente planejado no projeto
- **Princípio**: Testes sob demanda, não por padrão

#### CI/CD
- **Platform**: GitHub Actions
- **Quando usar**: Apenas quando automação for necessária
- **Princípio**: Deploy manual é aceitável para MVPs

#### Monitoring
- **Definir conforme projeto**: Escolher baseado em requisitos específicos
- **Exemplos de ferramentas**: 
  - Analytics: Collify, Posthog, Plausible, Umami
  - Error Tracking: Sentry, Rollbar, LogRocket
  - Observability: DataDog, New Relic, Grafana
- **Alternativa minimalista**: Serena MCP para logs e busca semântica
- **Quando usar**: Apenas se métricas forem requisito explícito
- **Princípio**: Console.log + busca semântica pode ser suficiente

#### Development Tools
- **Git Hooks**: Husky + lint-staged
- **Quando usar**: Se o time solicitar padronização
- **Princípio**: Linting local é suficiente para times pequenos

### 🚨 Princípio Fundamental

**NÃO implementar automaticamente:**
- ❌ Testes automáticos (fazer apenas quando planejado)
- ❌ Sistema de monitoramento (apenas se requisitado)
- ❌ CI/CD pipelines (avaliar necessidade real)
- ❌ Qualquer ferramenta não explicitamente pedida no STORIES.md

**Sempre verificar STORIES.md antes de adicionar complexidade.**

📝 **Nota sobre Flexibilidade**: As ferramentas listadas neste documento são apenas exemplos ilustrativos. A escolha real deve ser baseada em:
- Requisitos específicos do projeto (definidos em STORIES.md)
- Stack existente da equipe (ex: se já usam Collify, manter)
- Custo-benefício para o contexto específico
- Simplicidade como princípio norteador

> "A perfeição é atingida não quando não há mais nada para adicionar, mas quando não há mais nada para remover" - Antoine de Saint-Exupéry

## Alternative Stacks por Domínio

### Data Science & Epidemiologia
Baseado em: Epidemiology Decision Stack v1.0.0

#### Backend Options
- **FastAPI (Python)**: Para ML/Analytics, integração com notebooks científicos
- **Bun + Elysia + tRPC**: Type-safety automática, 3x mais rápido que FastAPI
- **Convex**: Backend reativo com sincronização automática e MCP nativo

#### Frontend para Dashboards
- **Remix + TypeScript**: SSR nativo, Progressive Enhancement, routing aninhado
- **Observable Plot**: Visualizações científicas reproduzíveis
- **Echarts**: Para sistemas legados em produção

#### Dados
- **Supabase**: Protótipos rápidos, real-time nativo, auth built-in
- **PostgreSQL + Drizzle ORM**: Controle fino sobre queries, migrations previsíveis
- **Convex Database**: Sincronização automática, reatividade

### Critérios de Decisão

#### Quando usar Stack Padrão (Rails)
- ✅ Aplicações web tradicionais
- ✅ CRUD pesado com convenções estabelecidas
- ✅ Times com expertise Ruby
- ✅ Projetos com prazo apertado

#### Quando usar Stack Data Science
- ✅ Dashboards analíticos e visualizações
- ✅ Integração com ML/Python
- ✅ Necessidade de real-time intensivo
- ✅ Processamento de dados científicos

#### Escolha por Tecnologia
**Protótipos/MVPs**: Supabase + Remix
**Produção com ML**: FastAPI + PostgreSQL
**Real-time intensivo**: Convex ou Supabase
**Visualização científica**: Observable Plot
**Apps tradicionais**: Rails + PostgreSQL

## Documentos de Referência

- [Prompt Engineering Guide](~/.agent-os/documentation/prompt-engineering-guide.md) - Práticas sistemáticas para melhorar prompts LLM
- [Epidemiology Decision Stack](~/.agent-os/documentation/epidemiology-stack.md) - Stack completa para sistemas de vigilância epidemiológica
- [Better T-Stack](https://www.better-t-stack.dev/) - Modern TypeScript stack with best practices
- [Remix Documentation](https://remix.run/docs) - Framework React moderno
- [FastAPI Documentation](https://fastapi.tiangolo.com) - API Python de alta performance
- [Observable Plot](https://observablehq.com/plot/) - Visualizações científicas
- [Drizzle ORM](https://orm.drizzle.team) - ORM TypeScript-first
- [Bun Runtime](https://bun.sh) - Runtime JavaScript/TypeScript rápido
