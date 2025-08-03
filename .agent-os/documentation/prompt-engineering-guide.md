# Prompt Engineering Guide

> "Programming in Natural Language" - A systematic approach to improving LLM applications

## What is Prompt Engineering?

The practice of systematically improving prompts for LLM applications through testing, evaluation, analysis, and optimization of prompts & tools.

## Core Concept

**Prompt Engineering is Often Conceptual Engineering** - It involves:
- Deciding the expected behavior for the model
- Determining what it means to perform well for the task
- Sharing crisp concepts

## Essential Skills

### 1. Clear, Unambiguous, Precise Writing
- Eliminate ambiguity in instructions
- Use specific, measurable criteria
- Define terms explicitly

### 2. Creating Evals with Scientific Mindset
- Test constantly with diverse inputs
- Measure performance quantitatively
- Iterate based on evidence

### 3. Product Thinking
- Define ideal model behavior for your product
- Understand user needs and edge cases
- Balance performance with user experience

### 4. Understanding LLMs
- Know model tendencies and limitations
- Recognize common failure patterns
- Work within context window constraints

### 5. Failure Analysis
- Aggregate and analyze failure modes
- Think systematically about fixes
- Document patterns and solutions

### 6. Edge Case Handling
- Anticipate unusual inputs
- Make prompts robust to wide range of inputs
- Test boundary conditions

## Practical Application

### Context Engineering > Prompt Engineering

While prompt engineering focuses on the query, context engineering provides:
- Complete system context
- Examples and patterns
- Constraints and boundaries
- Expected output formats

### Best Practices

1. **Version Control Prompts**
   - Track changes over time
   - A/B test variations
   - Document what works and why

2. **Create Test Suites**
   - Representative examples
   - Edge cases
   - Performance benchmarks

3. **Iterate Systematically**
   - Change one variable at a time
   - Measure impact
   - Document learnings

4. **Use Templates**
   - Consistent structure
   - Reusable components
   - Parameterized prompts

## Integration with Agent-OS

### PRD Template Integration
Use the Agent/IA section in PRD.md to specify:
- Model requirements
- Temperature settings
- Prompt templates
- Evaluation metrics

### Task Decomposition
Break complex prompts into subtasks:
- Each subtask has clear success criteria
- Chain prompts for complex workflows
- Maintain context between steps

## Example Prompt Evolution

### v1 - Basic
```
Summarize this text
```

### v2 - Specific
```
Summarize this text in 3 bullet points, focusing on key actionable insights
```

### v3 - Structured
```
Analyze the provided text and return:
- 3 key insights (actionable)
- Main conclusion (1 sentence)
- Confidence level (high/medium/low)
Format as JSON
```

### v4 - Context-Aware
```
You are a data analyst reviewing research findings.
Analyze the provided text considering:
- Statistical significance
- Practical implications
- Limitations

Return structured JSON with:
{
  "insights": ["insight1", "insight2", "insight3"],
  "conclusion": "main finding",
  "confidence": "high|medium|low",
  "limitations": ["limitation1", "limitation2"]
}
```

## Measurement & Evaluation

### Key Metrics
- **Accuracy**: Correct outputs / total
- **Consistency**: Variance across runs
- **Robustness**: Performance on edge cases
- **Latency**: Response time
- **Cost**: Tokens used

### Evaluation Framework
1. Define success criteria
2. Create test dataset
3. Run evaluations
4. Analyze failures
5. Iterate on prompts
6. Re-evaluate

## References

- [Anthropic Prompt Engineering Guide](https://docs.anthropic.com/claude/docs/prompt-engineering)
- [OpenAI Best Practices](https://platform.openai.com/docs/guides/prompt-engineering)
- PRD Template: `~/.agent-os/templates/PRD.md`
- Context Engineering: See CLAUDE.md principles