# Stack de Referência - Sistemas de Vigilância Epidemiológica

**Versão**: 1.0.0  
**Data**: Agosto 2025  
**Autor**: Bragatte, M.A.S  
**Contato**: marcelo.bragatte@itps.org.br

## Propósito

Este documento define a stack tecnológica padrão para sistemas de vigilância epidemiológica, servindo como referência para agentes e desenvolvedores na tomada de decisões técnicas. Considera o projeto Sinapse (docs.sinapse.org.br/tech) como referência futura para disponibilização de dados públicos de saúde.

## Princípios Norteadores

1. **Developer Experience (DX) Excepcional**: Priorizar produtividade sobre otimizações prematuras
2. **Type-Safety End-to-End**: Eliminar erros de tipo em tempo de compilação
3. **FAIR Compliance**: Findable, Accessible, Interoperable, Reusable
4. **Progressive Enhancement**: HTML-first para conexões lentas
5. **Escalabilidade Pragmática**: Começar simples, escalar quando necessário

## Stack Aprovada

### Estratégia de Dados - Duas Opções Paralelas

**Opção 1: Supabase (Protótipos e MVPs)**
- **Por quê**: Rápido para prototipar, real-time nativo, auth built-in
- **Quando**: Projetos novos, POCs, necessidade de tempo real
- **Projetos**: Detecta (login/multi-usuário), Revisa (drag-drop)

**Opção 2: API Endpoints Diretos (Produção e Integração)**
- **Por quê**: Controle total, integração com sistemas legados, preparação para Sinapse
- **Quando**: Sistemas em produção, integração com parceiros externos
- **Projetos**: Detecta Síndromes (análise ML), Positividade (dashboards públicos)

### Referência Futura: Projeto Sinapse
**docs.sinapse.org.br/tech**
- **Status**: Em desenvolvimento - referência de arquitetura para dados públicos
- **Relevância**: Nossos projetos devem considerar futura compatibilidade
- **Preparação**: APIs devem seguir OpenAPI 3.0, schemas versionados

### Backend
**Bun + Elysia + tRPC**
- **Por quê**: Type-safety automática, 3x mais rápido que FastAPI em benchmarks, validação integrada
- **Quando**: Novos microserviços e APIs que precisam de máxima performance

**FastAPI (mantido)**
- **Por quê**: Ecossistema Python maduro, integração nativa com ML, documentação automática
- **Quando**: APIs existentes, serviços ML/Analytics, integração com Sinapse

### Frontend  
**Remix + TypeScript + Tailwind CSS**
- **Por quê**: SSR nativo, Progressive Enhancement, routing aninhado
- **Quando**: Aplicações com múltiplas páginas e necessidade de SEO

### Banco de Dados
**PostgreSQL + Drizzle ORM + Supabase**
- **Por quê**: SQL-first approach, migrations previsíveis, performance superior
- **Quando**: Projetos que precisam de controle fino sobre queries e schema
- **Nota**: Apesar da falta de MCP oficial, mantemos Drizzle pela qualidade técnica

**Convex (Experimental)**
- **Por quê**: Backend reativo, sincronização automática, MCP nativo
- **Quando**: Detecta Estimativa (piloto), projetos com alta necessidade de reatividade
- **Futuro**: Potencial expansão para Extract e Detecta Síndromes

### Integração ML/Analytics
**Python (modelos) + Rust (hot paths) + TypeScript (clients)**
- **Por quê**: Ecossistema Python para ML, performance Rust onde crítico
- **Quando**: Sempre que houver processamento de dados ou ML

### Visualização de Dados
**Observable Plot**
- **Por quê**: Visualizações reativas, sintaxe analítica, notebooks computacionais integrados
- **Quando**: Padrão para todos os novos projetos de visualização epidemiológica
- **Benefícios**: Reprodutibilidade científica, análises vivas, menor código para gráficos complexos

**Echarts (Exceção)**
- **Por quê**: Manter estabilidade em sistema em produção
- **Quando**: Apenas para Detecta (sistema principal já estabelecido)

### OCR/Extração
**Scripts customizados (Docling Python + Rust)**
- **Por quê**: Controle total, LGPD compliance, sem custos de API
- **Quando**: Processamento de PDFs e documentos

### Armazenamento
**Estratégia**: Avaliar sempre se é necessário persistir dados
- **Dados estruturados**: PostgreSQL (preferência)
- **Arquivos/Blobs**: Supabase Storage
- **Fontes externas**: MinIO como origem (não destino)

## Arquitetura Padrão

```
monorepo/
├── apps/
│   ├── web/        → Remix frontend
│   ├── api/        → Elysia + tRPC backend  
│   ├── ml/         → Python services (FastAPI)
│   └── convex/     → Funções reativas (Detecta Estimativas)
├── packages/
│   ├── shared/     → Types compartilhados
│   ├── rust/       → Módulos Rust (maturin)
│   └── ui/         → Componentes Observable Plot reutilizáveis
└── docker-compose.yml
```

### Notas de Arquitetura
- Convex apps são desenvolvidos separadamente mas no monorepo
- Componentes Observable centralizados para criar linguagem visual consistente
- Types compartilhados garantem consistência entre stacks

## Padrões de Implementação

### API Design
- tRPC procedures para type-safety
- Zod para validação de entrada
- Streaming para uploads grandes

### Dados
- Schemas versionados (metadata FAIR)
- Índices em campos de busca frequente
- Soft deletes para auditoria

### Segurança
- JWT com refresh tokens
- Rate limiting por endpoint
- Validação em todas as entradas
- HTTPS obrigatório

### Performance
- Cache em múltiplas camadas
- Lazy loading de componentes pesados
- Workers para processamento assíncrono

## Detalhamento dos Projetos

### Detecta - Sistema Principal de Vigilância
**Funcionalidades**: Sistema com login, múltiplos usuários, relatórios semanais personalizados
**Stack Recomendada**: 
- Frontend: Remix + HTMX (híbrido para conexões ruins)
- Backend: FastAPI (compatibilidade futura com Sinapse)
- Dados: Supabase (auth + real-time para notificações)
- Visualização: Echarts (manter estabilidade em produção)
**Características Especiais**: Progressive enhancement para campo, cache agressivo para relatórios

### Detecta Síndromes - Análise de Padrões
**Funcionalidades**: Upload de dados temporais, detecção de padrões via ML, matrizes de indicadores
**Stack Recomendada**:
- Frontend: Remix + Observable Plot
- Backend: FastAPI + Python ML services
- Dados: PostgreSQL direto (volume de dados) + API endpoints
**Características Especiais**: Workers assíncronos para ML, visualizações analíticas interativas
**Futuro**: Candidato para Convex após sucesso do piloto Estimativas

### Detecta Estimativas - Previsões Automatizadas ⚡ CONVEX PILOT
**Funcionalidades**: Agregação de múltiplas fontes, modelos preditivos, atualização semanal automática
**Stack Recomendada**:
- Frontend: Remix + Observable Plot
- Backend: Convex (reatividade + MCP)
- Dados: Convex Database (sincronização automática)
**Características Especiais**: Funções reativas para recálculo automático, notebooks analíticos integrados

### Revisa - Análise Interativa com ML
**Funcionalidades**: Drag-drop de tabelas, processamento ML em tempo real, múltiplas abas de insights
**Stack Recomendada**:
- Frontend: Remix + React DnD + Observable Plot
- Backend: Bun + Elysia + tRPC (streaming)
- Dados: Supabase (real-time updates entre abas)
**Características Especiais**: ML pipeline on-demand, visualizações reativas em múltiplas abas

### Positividade - Dashboards Epidemiológicos
**Funcionalidades**: Indicadores públicos, múltiplas visualizações, integração com endpoints externos
**Stack Recomendada**:
- Frontend: Remix + Observable Plot
- Backend: FastAPI (cache robusto)
- Dados: PostgreSQL + Redis cache (MinIO apenas como fonte externa)
**Características Especiais**: Dashboards científicos reproduzíveis, narrativas analíticas

### Extract - Processamento de PDFs
**Funcionalidades**: OCR de fichas de notificação, extração para banco, integração REDCap
**Stack Recomendada**:
- Frontend: Remix + Observable Plot (para visualização de estatísticas de extração)
- Backend: FastAPI + Docling/Rust workers
- Dados: PostgreSQL + Supabase Storage
**Características Especiais**: Queue para processamento, métricas de qualidade de extração
**Futuro**: Potencial migração para Convex para processamento reativo

## Critérios de Decisão

### Quando usar Supabase
- ✅ Protótipos rápidos e MVPs
- ✅ Necessidade de real-time nativo
- ✅ Auth complexo com pouco código
- ✅ Armazenamento de arquivos/blobs

### Quando usar API Endpoints diretos
- ✅ Sistemas em produção estabelecidos
- ✅ Integração com parceiros externos
- ✅ Controle total sobre dados
- ✅ Preparação para integração futura com Sinapse

### Quando usar Convex (Experimental)
- ✅ Alta necessidade de reatividade e sincronização automática
- ✅ Benefício significativo do MCP para análise com AGIs
- ✅ Complexidade de agregação de múltiplas fontes
- ✅ Projetos piloto: Detecta Estimativas primeiro

### Quando usar FastAPI vs Bun/Elysia
- **FastAPI**: Serviços ML, compatibilidade Python, documentação automática
- **Bun/Elysia**: Máxima performance, type-safety crítico, real-time intensivo

## Métricas de Sucesso

- **Performance**: TTFB < 200ms (P95)
- **DX**: Setup completo < 10 minutos
- **Qualidade**: 60% menos bugs de tipo
- **Manutenção**: Deploy sem downtime

## Migração e Integração

### Estratégia Dual de Desenvolvimento
1. **Path Supabase**: Para protótipos rápidos e funcionalidades real-time
2. **Path API Endpoints**: Para produção e preparação para integração futura

### FastAPI → Nova Stack (quando aplicável)
1. Avaliar se o projeto se beneficia de type-safety extrema
2. Manter FastAPI para serviços ML e integrações Python
3. Migrar incrementalmente endpoints não-críticos
4. Manter ambas as stacks em paralelo quando necessário

### Preparação para Futuro (Sinapse)
- APIs devem seguir OpenAPI 3.0
- Schemas de dados versionados
- Documentação automática de endpoints
- Logs estruturados para futura centralização

## Referências Essenciais

- [Sinapse Platform](https://docs.sinapse.org.br/tech) - Referência futura para dados públicos
- [Remix Documentation](https://remix.run/docs)
- [tRPC Documentation](https://trpc.io)
- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [Drizzle ORM](https://orm.drizzle.team)
- [Bun Runtime](https://bun.sh)
- [Convex Documentation](https://docs.convex.dev)
- [Echarts Documentation](https://echarts.apache.org)
- [MCP Protocol](https://modelcontextprotocol.io)

## Support

For questions about implementation or architectural decisions, consult:
1. This document (always the latest version)
2. Reference examples in the monorepo
3. Architecture team via email

---

**Note**: This is a living document and should be updated as the stack evolves. Significant changes require a new version and team communication.