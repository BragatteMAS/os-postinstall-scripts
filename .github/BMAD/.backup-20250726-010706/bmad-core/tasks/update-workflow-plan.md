# Update Workflow Plan Task

## Purpose

Update the status of steps in an active workflow plan, mark completions, add notes about deviations, and maintain an accurate record of workflow progress. This task can be called directly by users or automatically by other tasks upon completion.

## Task Instructions

### 0. Load Plan Configuration

[[LLM: First load core-config.yaml to get plan settings]]

Check workflow configuration:

- `workflow.planFile` - Location of the plan (default: docs/workflow-plan.md)
- `workflow.trackProgress` - Whether tracking is enabled
- `workflow.updateOnCompletion` - Whether to auto-update on task completion

If tracking is disabled, inform user and exit.

### 1. Verify Plan Exists

[[LLM: Check if workflow plan exists at configured location]]

If no plan exists:

```
No active workflow plan found at {location}.
Would you like to create one? Use *plan command.
```

### 2. Determine Update Type

[[LLM: Ask user what type of update they want to make]]

Present options:

```
What would you like to update in the workflow plan?

1. Mark step as complete
2. Update current step
3. Add deviation note
4. Mark decision point resolution
5. Update overall status
6. View current plan status only

Please select an option (1-6):
```

### 3. Parse Current Plan

[[LLM: Read and parse the plan to understand current state]]

Extract:

- All steps with their checkbox status
- Step IDs from comments (if present)
- Current completion percentage
- Any existing deviation notes
- Decision points and their status

### 4. Execute Updates

#### 4.1 Mark Step Complete

If user selected option 1:

1. Show numbered list of incomplete steps
2. Ask which step to mark complete
3. Update the checkbox from `[ ]` to `[x]`
4. Add completion timestamp: `<!-- completed: YYYY-MM-DD HH:MM -->`
5. If this was the current step, identify next step

#### 4.2 Update Current Step

If user selected option 2:

1. Show all steps with current status
2. Ask which step is now current
3. Add/move `<!-- current-step -->` marker
4. Optionally add note about why sequence changed

#### 4.3 Add Deviation Note

If user selected option 3:

1. Ask for deviation description
2. Ask which step this relates to (or general)
3. Insert note in appropriate location:

```markdown
> **Deviation Note** (YYYY-MM-DD): {user_note}
> Related to: Step X.Y or General workflow
```

#### 4.4 Mark Decision Resolution

If user selected option 4:

1. Show pending decision points
2. Ask which decision was made
3. Record the decision and chosen path
4. Update related steps based on decision

#### 4.5 Update Overall Status

If user selected option 5:

1. Show current overall status
2. Provide options:
   - Active (continuing with plan)
   - Paused (temporarily stopped)
   - Abandoned (no longer following)
   - Complete (all steps done)
3. Update plan header with new status

### 5. Automatic Updates (When Called by Tasks)

[[LLM: When called automatically by another task]]

If called with parameters:

```
task: {task_name}
step_id: {step_identifier}
status: complete|skipped|failed
note: {optional_note}
```

Automatically:

1. Find the corresponding step
2. Update its status
3. Add completion metadata
4. Add note if provided
5. Calculate new progress percentage

### 6. Generate Update Summary

After updates, show summary:

```
✅ Workflow Plan Updated

Changes made:
- {change_1}
- {change_2}

New Status:
- Progress: {X}% complete ({completed}/{total} steps)
- Current Step: {current_step}
- Next Recommended: {next_step}

Plan location: {file_path}
```

### 7. Integration with Other Tasks

[[LLM: How other tasks should call this]]

Other tasks can integrate by:

1. **After Task Completion**:

```
At end of task execution:
- Check if task corresponds to a plan step
- If yes, call update-workflow-plan with:
  - task: {current_task_name}
  - step_id: {matching_step}
  - status: complete
```

2. **On Task Failure**:

```
If task fails:
- Call update-workflow-plan with:
  - task: {current_task_name}
  - status: failed
  - note: {failure_reason}
```

### 8. Plan Status Display

[[LLM: When user selects view status only]]

Display comprehensive status:

```markdown
📋 Workflow Plan Status
━━━━━━━━━━━━━━━━━━━━
Workflow: {workflow_name}
Status: {Active|Paused|Complete}
Progress: {X}% complete ({completed}/{total} steps)
Last Updated: {timestamp}

✅ Completed Steps:
- [x] Step 1.1: {description} (completed: {date})
- [x] Step 1.2: {description} (completed: {date})

🔄 Current Step:
- [ ] Step 2.1: {description} <!-- current-step -->
  Agent: {agent_name}
  Task: {task_name}

📌 Upcoming Steps:
- [ ] Step 2.2: {description}
- [ ] Step 3.1: {description}

⚠️ Deviations/Notes:
{any_deviation_notes}

📊 Decision Points:
- Decision 1: {status} - {choice_made}
- Decision 2: Pending

💡 Next Action:
Based on the plan, you should {recommended_action}
```

## Success Criteria

The update is successful when:

1. Plan accurately reflects current workflow state
2. All updates are clearly timestamped
3. Deviations are documented with reasons
4. Progress calculation is correct
5. Next steps are clear to user
6. Plan remains readable and well-formatted

## Error Handling

- **Plan file not found**: Offer to create new plan
- **Malformed plan**: Attempt basic updates, warn user
- **Write permission error**: Show changes that would be made
- **Step not found**: Show available steps, ask for clarification
- **Concurrent updates**: Implement simple locking or warn about conflicts

## Notes

- Always preserve plan history (don't delete old information)
- Keep updates atomic to prevent corruption
- Consider creating backup before major updates
- Updates should enhance, not complicate, the workflow experience
- If plan becomes too cluttered, suggest creating fresh plan for next phase
