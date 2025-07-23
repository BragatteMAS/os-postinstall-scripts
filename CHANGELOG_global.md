# Changelog - CLAUDE.md

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [2.3.0] - 2025-07-23
### Added
- Quick Start section no início do documento
- Serena como 4º MCP essencial
- Instruções para ativar os 4 MCPs por padrão
- Separação do changelog em arquivo dedicado

### Changed
- Reorganização para melhor fluxo de leitura
- MCPs agora são 4 por padrão (Context7, fetch, sequential-thinking, serena)
- Links consolidados para evitar redundância

### Removed
- Changelog do arquivo principal (movido para este arquivo)
- Referências externas desnecessárias (livros, comunidades)

## [2.2.0] - 2025-07-22
### Added
- Preferências técnicas específicas:
  - Python: UV para ambientes, Polars > pandas
  - Rust: Tipagem explícita e gestão de memória
  - React: Epic Stack patterns
- Links diretos para Epic Stack e ferramentas modernas

### Changed
- Seção de padrões de código mais específica por linguagem
- Versões recomendadas atualizadas

## [2.1.0] - 2025-07-22
### Added
- Sistema de auto-modulação contextual com diagrama de fluxo
- Protocolo detalhado para projetos existentes
- Exemplos específicos de bioinformática integrados
- Tabela de decisões STORIES → CLAUDE.md
- Seção sobre como decisões filtram o documento

### Changed
- Reorganização para destacar fluxo adaptativo no topo
- Melhorias nos exemplos de código com casos de bioinformática
- Expansão do protocolo de início para incluir verificação de PRD

### Fixed
- Clarificação de que nem todas as seções se aplicam sempre
- Alinhamento com fluxo real STATUS → PRD → STORIES → CLAUDE

## [2.0.0] - 2025-07-19
### Added
- CLAUDE-EXTENDED.md como documento complementar
- Context Engineering vs Prompt Engineering seção completa
- Testing Trophy com filosofia detalhada
- MCPs essenciais (Context7, fetch, sequential-thinking)
- Protocolo de captura de prompts [prompt-saved]

### Changed
- Reestruturação major para separar conteúdo básico vs. avançado
- Todos os exemplos extensos movidos para EXTENDED
- Foco em ser um documento operacional, não enciclopédico

## [1.5.0] - 2025-07-16
### Added
- Seção "Nunca Faça" expandida com 13 items
- Compatibilidade cross-platform com pathlib
- Padrões de commits convencionais
- Checklist de qualidade tripartite

### Changed
- Exemplos de código agora com comentários ## obrigatórios
- Melhor organização das referências rápidas

## [1.0.0] - 2025-07-12
### Added
- Integração oficial com BMAD Method
- Sistema de documentos essenciais (vermelho/roxo/amarelo)
- ADRs com diagramas Mermaid obrigatórios
- Filosofia de simplicidade com citações

### Changed
- Migração de guidelines soltas para sistema estruturado
- Priorização de STATUS.md como ponto de entrada

## [0.5.0] - 2025-07-08
### Added
- Protocolo de início de sessão
- Why-What-How como estrutura padrão
- Regras para artifacts
- Seção "Sempre Faça"

### Changed
- Refinamento dos princípios fundamentais
- Melhor definição de parceria intelectual

## [0.2.0] - 2025-07-04
### Added
- Princípios fundamentais básicos
- Estrutura inicial de comentários para R/Python
- Conceito de "documentação é código"

## [0.1.0] - 2025-07-01
- Primeiro rascunho do CLAUDE.md
- Ideia inicial de prevenir vibe-coding
- Estrutura básica inspirada em README.md