# CLAUDE-EXTENDED.md - Guia Detalhado de Referência

> **Versão:** 1.0.0 | **Atualizado:** 2025-01-23  
> **Propósito:** Detalhamento e expansão dos conceitos do CLAUDE.md  
> **⚠️ IMPORTANTE:** Este documento NÃO contém código hardcoded - use Context7 MCP para exemplos atualizados

---

## 📑 Índice

1. [Filosofia de Simplicidade](#filosofia-simplicidade)
2. [Context Engineering](#context-engineering)
3. [Testing Trophy](#testing-trophy)
4. [Padrões de Código](#padroes-codigo)
5. [Documentos do Projeto](#documentos-projeto)
6. [Versionamento Semântico](#versionamento-semantico)
7. [Comandos Slash](#comandos-slash)
8. [Captura de Prompts](#captura-prompts)
9. [Cross-Platform](#cross-platform)
10. [Modernidade](#modernidade)
11. [Código Agnóstico](#codigo-agnostico)

---

## 🎨 Filosofia de Simplicidade {#filosofia-simplicidade}

### Princípios Detalhados

#### 1. Simplicidade Emergente
- Complexidade deve emergir naturalmente, não ser forçada
- Comece com a solução mais simples possível
- Adicione complexidade apenas quando dados reais justificarem
- Documente o "porquê" de cada complexidade adicionada

#### 2. Antipadrões Comuns
- **Over-engineering**: Abstrações desnecessárias
- **Premature optimization**: Otimizar sem métricas
- **Pattern addiction**: Usar padrões por usar
- **Framework fever**: Adicionar frameworks sem necessidade real

#### 3. Checklist de Validação
Antes de implementar qualquer solução:
- [ ] Existe uma biblioteca que já resolve isso?
- [ ] A solução cabe em uma página?
- [ ] Um júnior entenderia em 10 minutos?
- [ ] Os testes são simples de escrever?
- [ ] A manutenção será óbvia?

### Como Aplicar

1. **Start Small**: Sempre comece com MVP mínimo
2. **Iterate**: Adicione features baseado em uso real
3. **Measure**: Use métricas para justificar complexidade
4. **Refactor**: Simplifique constantemente

---

## 🎭 Context Engineering {#context-engineering}

### Por que Context > Prompt

#### Diferenças Fundamentais

**Prompt Engineering:**
- Foco em como formular a pergunta
- Resultados inconsistentes
- Depende do modelo entender implicitamente
- Difícil de debugar falhas

**Context Engineering:**
- Sistema completo de informações
- Resultados previsíveis e consistentes
- Contexto explícito reduz ambiguidade
- Falhas são rastreáveis

### Componentes do Context Engineering

#### 1. Estrutura de Arquivos
```
project/
├── docs/
│   ├── PRD.md          # Objetivos e contexto
│   ├── STORIES.md      # Jornadas e decisões
│   ├── STATUS.md       # Estado atual
│   └── ADRs/           # Decisões arquiteturais
├── examples/           # Padrões de código
└── .claude/
    └── commands/       # Comandos customizados
```

#### 2. Documentação Viva
- PRD define o "porquê" e "o quê"
- STORIES captura jornadas de usuário
- STATUS mantém estado atual
- ADRs documentam decisões técnicas

#### 3. Exemplos como Contratos
- Pasta `examples/` com padrões reais do projeto
- Testes como documentação executável
- Commits anteriores como referência de estilo

### Estratégias Avançadas

#### 1. Layered Context
- **L1**: Contexto global (CLAUDE.md)
- **L2**: Contexto do projeto (PRD, STORIES)
- **L3**: Contexto da feature (ADRs, examples)
- **L4**: Contexto da tarefa (issue, PR)

#### 2. Context Validation
- Gates automáticos em cada camada
- Verificação de consistência
- Alertas para contexto desatualizado

#### 3. Context Evolution
- Contexto evolui com o projeto
- Capture decisões em tempo real
- Mantenha histórico de mudanças

---

## 🏆 Testing Trophy {#testing-trophy}

### Filosofia Central

A Testing Trophy inverte a pirâmide tradicional:
- **Muitos testes de integração** (base larga)
- **Alguns unit tests** (meio)
- **Poucos E2E tests** (topo)
- **Static checks** (fundação)

### Por que Testing Trophy?

1. **ROI Superior**: Testes de integração pegam mais bugs
2. **Menos Fragilidade**: Menos acoplamento com implementação
3. **Refactoring Confidence**: Mude implementação sem quebrar testes
4. **User-Centric**: Testa comportamento, não detalhes

### Implementação Prática

#### 1. Priorize Integration Tests
- Teste fluxos completos de features
- Mock apenas boundaries (DB, API externa)
- Use dados realistas

#### 2. Unit Tests Estratégicos
- Apenas para lógica complexa isolada
- Algoritmos matemáticos/estatísticos
- Funções utilitárias puras

#### 3. E2E Tests Críticos
- Happy path principal
- Fluxos de pagamento/autenticação
- Features críticas de negócio

#### 4. Static Analysis
- TypeScript/Rust para type safety
- Linters para estilo consistente
- Formatters automáticos

### Queries Semânticas (Acessibilidade)

Sempre use queries que usuários reais usariam:

1. **getByRole** - Elementos por função semântica
2. **getByLabelText** - Inputs por label
3. **getByText** - Conteúdo visível
4. **getByPlaceholderText** - Último recurso

**NUNCA** use `data-testid` - isso força componentes acessíveis.

---

## 📝 Padrões de Código {#padroes-codigo}

### Python com UV e Polars {#python-r-exemplos}

#### Setup com UV
```bash
# Use Context7 para exemplos atualizados de UV
"Como configurar projeto Python com UV e polars. use context7"
```

#### Princípios Python
1. **Type hints sempre**: Melhora IDE e catches bugs
2. **Polars over pandas**: Performance 10-100x superior
3. **Async quando apropriado**: Para I/O bound tasks
4. **Dataclasses/Pydantic**: Para estruturas de dados

#### Princípios R
1. **Tidyverse sempre**: Consistência e legibilidade
2. **here::here()**: Paths relativos robustos
3. **Functional style**: map/reduce over loops
4. **Explicit namespaces**: pkg::function()

### Rust com Tipagem Explícita {#rust-exemplos}

#### Princípios de Tipagem
1. **Tipos customizados**: NewType pattern para domínio
2. **Lifetimes explícitos**: Quando compiler não infere
3. **Error types ricos**: Não use Box<dyn Error>
4. **Zero-cost abstractions**: Traits over runtime dispatch

#### Gestão de Memória
1. **Ownership clara**: Minimize clones desnecessários
2. **Borrowing eficiente**: &str > String quando possível
3. **Smart pointers**: Rc/Arc apenas quando necessário
4. **RAII sempre**: Recursos limpos automaticamente

### React/TypeScript Epic Stack {#react-typescript-exemplos}

#### Arquitetura Epic Stack
```bash
# Use Context7 para estrutura atualizada
"Estrutura de projeto Epic Stack com Remix. use context7"
```

#### Princípios Epic Stack
1. **Progressive Enhancement**: Funciona sem JS
2. **Type Safety End-to-End**: Zod schemas compartilhados
3. **Database-First**: Prisma para type safety
4. **Testing Integration**: Vitest + Testing Library

---

## 📋 Documentos do Projeto {#documentos-projeto}

### Templates Detalhados

#### PRD.md Template
```markdown
# Product Requirements Document

## Visão Geral
[Descrição concisa do produto/feature]

## Objetivos
- [ ] Objetivo mensurável 1
- [ ] Objetivo mensurável 2

## Métricas de Sucesso
- KPI 1: [Definição e meta]
- KPI 2: [Definição e meta]

## Premissas e Restrições
- Premissa 1
- Restrição 1

## Perguntas Abertas
- [ ] Pergunta que precisa resposta
- [ ] Decisão pendente

## Cronograma
- Milestone 1: [Data]
- Milestone 2: [Data]
```

#### STORIES.md Template
```markdown
# User Stories e Jornadas

## Perguntas Focais (Context Filtering)
**Q: Precisa de testes?** A: [Sim/Não e justificativa]
**Q: Tem interface visual?** A: [Tipo de interface]
**Q: Qual o volume de dados?** A: [Estimativa]

## Jornada Principal
Como [persona], eu quero [ação] para [benefício]

### Critérios de Aceitação
- [ ] Critério verificável 1
- [ ] Critério verificável 2

### PRP (Product Requirements Prompt)
[Contexto completo para implementação]
```

#### STATUS.md Template
```markdown
# Status do Projeto

## Resumo
[Estado atual em 1-2 frases]

## Progresso
- [x] Fase 1: Completa
- [ ] Fase 2: Em andamento (70%)
- [ ] Fase 3: Não iniciada

## Documentação
| Documento | Última Atualização | Status |
|-----------|-------------------|---------|
| PRD.md | 2025-01-20 | 🟢 |
| STORIES.md | 2025-01-19 | 🟡 |
| CLAUDE.md | 2025-01-01 | 🔴 |

## Blockers
- [ ] Blocker 1: [Descrição e owner]

## Próximos Passos
1. Ação imediata
2. Ação seguinte
```

### Ciclo de Vida dos Documentos

1. **Criação**: PRD → STORIES → STATUS
2. **Evolução**: Atualize conforme aprende
3. **Revisão**: Monthly para docs principais
4. **Arquivamento**: Versione decisões antigas

---

## 📊 Versionamento Semântico {#versionamento-semantico}

### Estratégia Simplificada

Usamos **Semantic Versioning**: `MAJOR.MINOR.PATCH`

#### Decisão Rápida

```
Quebra compatibilidade? → MAJOR (3.0.0)
Adiciona feature? → MINOR (2.4.0)  
Corrige bug? → PATCH (2.3.1)
```

#### Detalhamento

**MAJOR (X.0.0)**
- Mudanças que quebram uso existente
- Remoção de features
- Mudança de sintaxe de comandos
- Arquitetura nova

**MINOR (0.X.0)**
- Features novas sem quebrar existentes
- Novos comandos/opções
- Suporte a nova plataforma
- Melhorias significativas

**PATCH (0.0.X)**
- Correções de bugs
- Melhorias de performance
- Atualizações de documentação
- Ajustes de segurança

### Pre-releases

```bash
2.3.1-alpha.1  # Primeira tentativa
2.3.1-alpha.4  # Quarta iteração
2.3.1-beta.1   # Feature complete, testando
2.3.1          # Estável
```

### Tags vs Branches

**Tags para:**
- Releases: `v2.3.0`
- Milestones: `v2.3.1-alpha.4`

**Branches para:**
- Desenvolvimento: `feature/nome`
- Correções: `fix/nome`

### Integração com ROADMAP

```markdown
## v2.4.0 - Profile Enhancement ⬆️ MINOR
- Custom profiles
- Profile inheritance

## v3.0.0 - Breaking Changes ⬆️ MAJOR  
- Nova sintaxe CLI
- Remove suporte Ubuntu 20.04
```

### Commits e Versões

```bash
# Features → próximo MINOR
feat: add data scientist profile

# Fixes → próximo PATCH
fix: correct APT timeout

# Breaking → próximo MAJOR
BREAKING CHANGE: remove Python 2 support
```

---

## 🔨 Comandos Slash {#comandos-slash}

### Criando Comandos Customizados

#### Estrutura Básica
```
.claude/
└── commands/
    ├── generate-prp.md
    ├── validate-code.md
    └── analyze-performance.md
```

#### Anatomia de um Comando
```markdown
# /generate-prp

Generate a complete Product Requirements Prompt from user requirements.

## Instructions
1. Analyze the user's request
2. Extract key requirements
3. Generate structured PRP
4. Include validation gates
5. Add success metrics

## Output Format
[Structured template for PRP]
```

### Comandos Recomendados

1. **/generate-prp**: Cria PRPs completos
2. **/validate-patterns**: Verifica aderência
3. **/analyze-complexity**: Detecta over-engineering
4. **/suggest-refactor**: Propõe simplificações
5. **/update-status**: Atualiza STATUS.md

### Best Practices

1. **Comandos atômicos**: Uma responsabilidade
2. **Output estruturado**: Formato consistente
3. **Validação incluída**: Gates automáticos
4. **Documentação clara**: Exemplos de uso

---

## 📸 Captura de Prompts {#captura-prompts}

### Sistema de Captura

#### Trigger Automático
Commits com `[prompt-saved]` salvam automaticamente:
```bash
git commit -m "feat: add auth flow [prompt-saved]"
```

#### Estrutura de Armazenamento
```
.claude/
└── prompts/
    ├── 2025-01/
    │   ├── auth-implementation.md
    │   └── performance-optimization.md
    └── categories/
        ├── backend.md
        └── frontend.md
```

### Formato de Captura

#### Metadados Essenciais
- **Data/Hora**: Timestamp ISO
- **Categoria**: Backend/Frontend/Data/Infra
- **Tags**: #performance #security #refactor
- **Métricas**: Tempo economizado, bugs evitados

#### Template
```markdown
## [2025-01-23] - Backend: API Rate Limiting

**Contexto:** Precisava implementar rate limiting sem biblioteca externa

**Prompt:** [Prompt exato usado]

**Resultado:** 
- Implementação funcional em 30 min
- 0 dependências externas
- Tests incluídos

**Métricas:**
- Tempo: 2h → 30min (75% economia)
- Complexidade: Média → Baixa

**Decisões CLAUDE.md:**
- ✅ Seção Testing Trophy aplicada
- ❌ Seção React ignorada (backend puro)
```

### Análise e Evolução

1. **Review mensal**: Identifique padrões
2. **Categorize**: Agrupe por tipo/sucesso
3. **Evolua**: Transforme em comandos slash
4. **Compartilhe**: PRs com prompts úteis

---

## 🌐 Cross-Platform {#cross-platform}

### Estratégias por Linguagem

#### Python
- `pathlib.Path` para todos os caminhos
- `platform.system()` para detecção de OS
- `sys.platform` para detalhes específicos
- Evite `os.path.join()` legado

#### Rust
- `std::path::Path` e `PathBuf`
- `cfg!` macros para compile-time
- `target_os` para conditional compilation
- Cross-platform crates quando disponível

#### Node.js/TypeScript
- `path.join()` over string concatenation
- `process.platform` para detecção
- npm scripts para comandos OS-specific
- Evite shell commands diretos

### Problemas Comuns

1. **Line Endings**: Configure `.gitattributes`
2. **File Permissions**: Seja explícito quando necessário
3. **Case Sensitivity**: Assuma case-sensitive sempre
4. **Path Separators**: Nunca hardcode / ou \
5. **Encoding**: UTF-8 everywhere, seja explícito

### Testing Cross-Platform

1. **CI Matrix**: Test em Linux/Mac/Windows
2. **Docker**: Containers para ambientes consistentes
3. **Virtual Envs**: Isolamento de dependências
4. **Mock OS-specific**: Para unit tests

---

## 🚀 Modernidade {#modernidade}

### Sinais de Código Moderno

#### ✅ Práticas Modernas
1. **Async/Await**: Sem callback hell
2. **Type Safety**: TypeScript, Rust, type hints
3. **Functional Style**: Immutability, pure functions
4. **Modern Tooling**: Vite, esbuild, SWC
5. **Container-First**: Docker from day one

#### 🚩 Red Flags Detalhados

**Dependency Red Flags:**
- Last update > 2 years
- No TypeScript definitions
- jQuery in new projects
- Moment.js (use date-fns/dayjs)
- Request/Axios (use fetch)

**Code Red Flags:**
- Callback pyramids
- Global variables
- Mutable shared state
- No error boundaries
- Sync blocking operations

**Architecture Red Flags:**
- Monolithic without reason
- No separation of concerns
- Tight coupling everywhere
- No dependency injection
- Hard-coded configuration

### Estratégias de Modernização

1. **Incremental**: Modernize por módulo
2. **Measure Impact**: Métricas antes/depois
3. **Documentation**: ADRs para cada mudança
4. **Training**: Time precisa entender o porquê
5. **Rollback Plan**: Sempre tenha saída

---

## 🔧 Código Agnóstico {#codigo-agnostico}

### Princípios de Agnosticismo

#### 1. Detecção em Runtime
```bash
# Use Context7 para exemplos de detecção
"Como detectar ambiente em Python/Rust/Node. use context7"
```

#### 2. Configuration Over Code
- Variáveis de ambiente
- Config files por ambiente
- Feature flags para comportamento
- Dependency injection

#### 3. Abstração de Plataforma
- Interfaces para serviços externos
- Adapters para diferentes implementações
- Factory patterns para criação
- Strategy pattern para comportamento

### Patterns Agnósticos

1. **Environment Variables**: 12-factor app
2. **Config Objects**: Centralize configuração
3. **Service Interfaces**: Abstraia dependências
4. **Plugin Architecture**: Extensibilidade
5. **Feature Toggles**: Comportamento dinâmico

### Anti-Patterns

1. **Hardcoded paths**: Use config/env vars
2. **Fixed versions**: Use ranges apropriados
3. **OS-specific code**: Abstraia em módulos
4. **Vendor lock-in**: Use abstrações
5. **Assume environment**: Sempre detecte

---

> **Nota Final:** Este documento é um complemento vivo ao CLAUDE.md. Use Context7 MCP para exemplos de código atualizados.