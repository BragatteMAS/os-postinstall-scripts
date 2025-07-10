# Create Workflow Plan Task

## Purpose

Guide users through workflow selection and create a detailed plan document that outlines the selected workflow steps, decision points, and expected outputs. This task helps users understand what will happen before starting a complex workflow and provides a checklist to track progress.

## Task Instructions

### 1. Understand User's Goal

[[LLM: Start with discovery questions to understand what the user wants to accomplish]]

Ask the user:

1. **Project Type**:
   - Are you starting a new project (greenfield) or enhancing an existing one (brownfield)?
   - What type of application? (web app, service/API, UI only, full-stack)

2. **For Greenfield**:
   - Do you need a quick prototype or production-ready application?
   - Will this have a UI component?
   - Single service or multiple services?

3. **For Brownfield**:
   - What's the scope of the enhancement?
     - Single bug fix or small feature (few hours)
     - Small enhancement (1-3 stories)
     - Major feature requiring coordination
     - Architectural changes or modernization
   - Do you have existing documentation?
   - Are you following existing patterns or introducing new ones?

### 2. Recommend Appropriate Workflow

Based on the answers, recommend:

**Greenfield Options:**

- `greenfield-fullstack` - Complete web application
- `greenfield-service` - Backend API/service only
- `greenfield-ui` - Frontend only

**Brownfield Options:**

- `brownfield-create-story` - Single small change
- `brownfield-create-epic` - Small feature (1-3 stories)
- `brownfield-fullstack` - Major enhancement

**Simplified Option:**

- For users unsure or wanting flexibility, suggest starting with individual agent tasks

### 3. Explain Selected Workflow

[[LLM: Once workflow is selected, provide clear explanation]]

For the selected workflow, explain:

1. **Overview**: What this workflow accomplishes
2. **Duration**: Estimated time for planning phase
3. **Outputs**: What documents will be created
4. **Decision Points**: Where user input will be needed
5. **Requirements**: What information should be ready

### 4. Create Workflow Plan Document

[[LLM: Generate a comprehensive plan document with the following structure]]

```markdown
# Workflow Plan: {{Workflow Name}}

<!-- WORKFLOW-PLAN-META
workflow-id: {{workflow-id}}
status: active
created: {{ISO-8601 timestamp}}
updated: {{ISO-8601 timestamp}}
version: 1.0
-->

**Created Date**: {{current date}}
**Project**: {{project name}}
**Type**: {{greenfield/brownfield}}
**Status**: Active
**Estimated Planning Duration**: {{time estimate}}

## Objective

{{Clear description of what will be accomplished}}

## Selected Workflow

**Workflow**: `{{workflow-id}}`
**Reason**: {{Why this workflow fits the user's needs}}

## Workflow Steps

### Planning Phase

- [ ] Step 1: {{step name}} <!-- step-id: 1.1, agent: {{agent}}, task: {{task}} -->
  - **Agent**: {{agent name}}
  - **Action**: {{what happens}}
  - **Output**: {{what's created}}
  - **User Input**: {{if any}}

- [ ] Step 2: {{step name}} <!-- step-id: 1.2, agent: {{agent}}, task: {{task}} -->
  - **Agent**: {{agent name}}
  - **Action**: {{what happens}}
  - **Output**: {{what's created}}
  - **Decision Point**: {{if any}} <!-- decision-id: D1 -->

{{Continue for all planning steps}}

### Development Phase (IDE)

- [ ] Document Sharding <!-- step-id: 2.1, agent: po, task: shard-doc -->
  - Prepare documents for story creation

- [ ] Story Development Cycle <!-- step-id: 2.2, repeats: true -->
  - [ ] Create story (SM agent) <!-- step-id: 2.2.1, agent: sm, task: create-next-story -->
  - [ ] Review story (optional) <!-- step-id: 2.2.2, agent: analyst, optional: true -->
  - [ ] Implement story (Dev agent) <!-- step-id: 2.2.3, agent: dev -->
  - [ ] QA review (optional) <!-- step-id: 2.2.4, agent: qa, optional: true -->
  - [ ] Repeat for all stories

- [ ] Epic Retrospective (optional) <!-- step-id: 2.3, agent: po, optional: true -->

## Key Decision Points

1. **{{Decision Name}}** (Step {{n}}): <!-- decision-id: D1, status: pending -->
   - Trigger: {{what causes this decision}}
   - Options: {{available choices}}
   - Impact: {{how it affects the workflow}}
   - Decision Made: _Pending_

{{List all decision points}}

## Expected Outputs

### Planning Documents
- [ ] {{document 1}} - {{description}}
- [ ] {{document 2}} - {{description}}
{{etc...}}

### Development Artifacts
- [ ] Stories in `docs/stories/`
- [ ] Implementation code
- [ ] Tests
- [ ] Updated documentation

## Prerequisites Checklist

Before starting this workflow, ensure you have:

- [ ] {{prerequisite 1}}
- [ ] {{prerequisite 2}}
- [ ] {{prerequisite 3}}
{{etc...}}

## Customization Options

Based on your project needs, you may:
- Skip {{optional step}} if {{condition}}
- Add {{additional step}} if {{condition}}
- Choose {{alternative}} instead of {{default}}

## Risk Considerations

{{For brownfield only}}
- Integration complexity: {{assessment}}
- Rollback strategy: {{approach}}
- Testing requirements: {{special needs}}

## Next Steps

1. Review this plan and confirm it matches your expectations
2. Gather any missing prerequisites
3. Start workflow with: `*task workflow {{workflow-id}}`
4. Or begin with first agent: `@{{first-agent}}`

## Notes

{{Any additional context or warnings}}

---
*This plan can be updated as you progress through the workflow. Check off completed items to track progress.*
```

### 5. Save and Present Plan

1. Save the plan as `docs/workflow-plan.md`
2. Inform user: "Workflow plan created at docs/workflow-plan.md"
3. Offer options:
   - Review the plan together
   - Start the workflow now
   - Gather prerequisites first
   - Modify the plan

### 6. Plan Variations

[[LLM: Adjust plan detail based on workflow complexity]]

**For Simple Workflows** (create-story, create-epic):

- Simpler checklist format
- Focus on immediate next steps
- Less detailed explanations

**For Complex Workflows** (full greenfield/brownfield):

- Detailed step breakdowns
- All decision points documented
- Comprehensive output descriptions
- Risk mitigation sections

**For Brownfield Workflows**:

- Include existing system impact analysis
- Document integration checkpoints
- Add rollback considerations
- Note documentation dependencies

### 7. Interactive Planning Mode

[[LLM: If user wants to customize the workflow]]

If user wants to modify the standard workflow:

1. Present workflow steps as options
2. Allow skipping optional steps
3. Let user reorder certain steps
4. Document customizations in plan
5. Warn about dependencies if steps are skipped

### 8. Execution Guidance

After plan is created, provide clear guidance:

```text
Your workflow plan is ready! Here's how to proceed:

1. **Review the plan**: Check that all steps align with your goals
2. **Gather prerequisites**: Use the checklist to ensure you're ready
3. **Start execution**:
   - Full workflow: `*task workflow {{workflow-id}}`
   - Step by step: Start with `@{{first-agent}}`
4. **Track progress**: Check off steps in the plan as completed

Would you like to:
a) Review the plan together
b) Start the workflow now
c) Gather prerequisites first
d) Modify the plan
```

## Success Criteria

The workflow plan is successful when:

1. User clearly understands what will happen
2. All decision points are documented
3. Prerequisites are identified
4. Expected outputs are clear
5. User feels confident to proceed
6. Plan serves as useful progress tracker

## Integration with BMad Master and Orchestrator

When used by BMad Master or BMad Orchestrator, this task should:

1. Be offered when user asks about workflows
2. Be suggested before starting complex workflows
3. Create a plan that the agent can reference during execution
4. Allow the agent to track progress against the plan

## Example Usage

```text
User: "I need to add a payment system to my existing app"

BMad Orchestrator: "Let me help you create a workflow plan for that enhancement. I'll ask a few questions to recommend the best approach..."

[Runs through discovery questions]

BMad Orchestrator: "Based on your answers, I recommend the brownfield-fullstack workflow. Let me create a detailed plan for you..."

[Creates and saves plan]

BMad Orchestrator: "I've created a workflow plan at docs/workflow-plan.md. This shows all the steps we'll go through, what documents will be created, and where you'll need to make decisions. Would you like to review it together?"
```
