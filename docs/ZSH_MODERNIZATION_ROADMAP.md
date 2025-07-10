# PRD - Modernização do .zshrc Científico

## 📋 Objetivo
Transformar o .zshrc em um ambiente científico moderno, consistente e automatizado, priorizando ferramentas Rust e eliminando redundâncias.

## 🎯 Status Geral: ~65% Completo

---

## FASE 1: Sistema de Verificação e Instalação
**Status**: 0% ⬜⬜⬜⬜⬜

### Task 1.1: Reescrever SEÇÃO 2 com instalação automática
- [ ] 1.1.1: Criar arrays de ferramentas por categoria
- [ ] 1.1.2: Implementar detecção de SO e gerenciador
- [ ] 1.1.3: Adicionar instalação em lote
- [ ] 1.1.4: Criar modo não-interativo

### Task 1.2: Criar função de verificação pós-instalação
- [ ] 1.2.1: Validar cada ferramenta instalada
- [ ] 1.2.2: Reportar falhas com soluções
- [ ] 1.2.3: Marcar .zshrc_installed quando completo

---

## FASE 2: Limpeza e Padronização
**Status**: 80% ⬜⬜⬜⬜⬛

### Task 2.1: Converter comentários cabeçalhos para inglês ✅
- [x] Headers de seção convertidos
- [x] Estrutura padronizada

### Task 2.2: Eliminar redundâncias grep/rg ✅
- [x] Removido alias grep='rg'
- [x] Uso direto de rg em todo arquivo
- [x] Removidos fallbacks

### Task 2.3: Remover aliases redundantes ✅
- [x] Consolidado aliases de clear
- [x] Removido header path específico
- [x] Python/pip consolidado

### Task 2.4: Converter TODOS os textos/outputs para inglês ⬜
- [ ] 2.4.1: Mensagens de erro e sucesso
- [ ] 2.4.2: Descrições de funções
- [ ] 2.4.3: Comentários inline restantes

### Task 2.5: Adicionar suporte UV e seção personalizada conda ✅
- [x] UV como alternativa ao pip
- [x] Seção HERE para ambientes pessoais
- [x] Suporte pixi adicionado

---

## FASE 3: Sistema de Tracking Corrigido
**Status**: 70% ⬜⬜⬜⬛⬛

### Task 3.1: Corrigir tracking de comandos (SEÇÃO 21.1) ✅
- [x] 3.1.1: Corrigir erro linha 857
- [x] 3.1.2: Implementar sistema precmd
- [ ] 3.1.3: Testar em macOS e Linux

### Task 3.2: Atualizar função hal() ⬜
- [x] 3.2.1: Melhorar formatação TOP 5
- [ ] 3.2.2: Adicionar validações adicionais
- [ ] 3.2.3: Implementar período customizável

---

## FASE 4: Correção Funções Nushell (SEÇÃO 14)
**Status**: 25% ⬜⬛⬛⬛⬛

### Task 4.1: Corrigir funções Nushell
- [x] 4.1.1: Simplificar nu_csv() temporariamente
- [ ] 4.1.2: Restaurar funcionalidade completa nu_csv()
- [ ] 4.1.3: Corrigir nu_project_stats()
- [ ] 4.1.4: Corrigir nu_compare()
- [ ] 4.1.5: Validar todas as funções nu

---

## FASE 5: Otimizações e Features
**Status**: 0% ⬜⬜⬜⬜⬜

### Task 5.1: Implementar escolha Starship vs P10k
- [ ] 5.1.1: Detectar se já configurado
- [ ] 5.1.2: Criar prompt de escolha
- [ ] 5.1.3: Auto-configurar tema escolhido

### Task 5.2: Adicionar novas ferramentas
- [ ] 5.2.1: Integrar xsv para CSV
- [ ] 5.2.2: Adicionar httpie
- [ ] 5.2.3: Configurar btop

### Task 5.3: Otimizar performance
- [ ] 5.3.1: Implementar lazy loading
- [ ] 5.3.2: Cachear verificações
- [ ] 5.3.3: Reduzir tempo de inicialização

---

## FASE 6: Documentação e Finalização
**Status**: 10% ⬜⬛⬛⬛⬛

### Task 6.1: Criar README.md
- [ ] 6.1.1: Listar todas ferramentas
- [ ] 6.1.2: Instruções de instalação
- [ ] 6.1.3: Troubleshooting comum

### Task 6.2: Adicionar testes
- [ ] 6.2.1: Script de validação
- [ ] 6.2.2: Verificar todos aliases
- [ ] 6.2.3: Testar em macOS e Linux

### Task 6.3: Adicionar ## em TODOS os comentários ✅
- [x] 6.3.1: Revisão completa de comentários
- [x] 6.3.2: Padronização de formato

---

## FASE 7: Correções de Consistência (NOVA)
**Status**: 100% ⬜⬜⬜⬜⬜

### Task 7.1: Padronizar idioma ✅
- [x] 7.1.1: Todos os títulos de seção em inglês
- [x] 7.1.2: Mensagens de boas-vindas em inglês
- [x] 7.1.3: Remover duplicações finais

---

## 📊 Métricas de Progresso

| Fase | Tarefas | Completas | Progresso |
|------|---------|-----------|-----------|
| 1 | 7 | 0 | 0% |
| 2 | 8 | 6 | 75% |
| 3 | 6 | 4 | 67% |
| 4 | 5 | 1 | 20% |
| 5 | 9 | 0 | 0% |
| 6 | 9 | 2 | 22% |
| 7 | 3 | 3 | 100% |
| **TOTAL** | **47** | **16** | **34%** |

---

## 🎯 Próximas Ações Prioritárias

1. **Testar arquivo atual** - Verificar se não há mais erros
2. **Task 4.1.2-4** - Restaurar funcionalidade completa do Nushell
3. **Task 1.1** - Implementar instalação automática
4. **Task 5.1** - Escolha Starship vs P10k

---

## 📝 Notas

- Priorizar correções que bloqueiam uso básico
- Manter compatibilidade macOS/Linux
- Documentar todas as mudanças
- Testar incrementalmente

---

## 🐛 Bugs Conhecidos

1. ~~Tracking de comandos com recursão~~ ✅ Corrigido
2. ~~Funções Nushell com erro de sintaxe~~ ⚠️ Simplificado temporariamente
3. ~~Duplicação de código~~ ✅ Corrigido

---

## 📅 Timeline Estimada

- **Fase 1-3**: 2-3 horas (correções críticas)
- **Fase 4-5**: 3-4 horas (features e otimizações)
- **Fase 6**: 2 horas (documentação e testes)

**Total estimado**: 7-9 horas de trabalho