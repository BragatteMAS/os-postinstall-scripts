---
defaultOutput: docs/stories/{{EpicNum}}.{{StoryNum}}.{{Short Title Copied from Epic File specific story}}.md
smAgent:
  editableSections: Status, Story, Acceptance Criteria, Tasks / Subtasks, Dev Notes, Testing, Change Log
  sectionSpecificInstructions:
    "Dev Notes":
      - Populate relevant information, only what was pulled from actual artifacts from docs folder, relevant to this story
      - Do not invent information.
      - If known add Relevant Source Tree info that relates to this story.
      - If there were important notes from previous story that are relevant to this one, include them here.
      - Put enough information in this section so that the dev agent should NEVER need to read the architecture documents, these notes along with the tasks and subtasks must give the Dev Agent the complete context it needs to comprehend with the least amount of overhead the information to complete the story,  meeting all AC and completing all tasks+subtasks.
    Testing:
      - List Relevant Testing Standards from Architecture the Developer needs to conform to (test file location, test standards, etc) 
---

# Story {{EpicNum}}.{{StoryNum}}: {{Short Title Copied from Epic File specific story}}

## Status: {{ Draft | Approved | InProgress | Review | Done }}

## Story

**As a** {{role}},\
**I want** {{action}},\
**so that** {{benefit}}

## Acceptance Criteria

{{ Copy of Acceptance Criteria numbered list }}

## Tasks / Subtasks

- [ ] Task 1 (AC: # if applicable)
  - [ ] Subtask1.1...
- [ ] Task 2 (AC: # if applicable)
  - [ ] Subtask 2.1...
- [ ] Task 3 (AC: # if applicable)
  - [ ] Subtask 3.1...

## Dev Notes

### Testing

## Change Log

| Date | Version | Description | Author |
| :--- | :------ | :---------- | :----- |

## Dev Agent Record

### Agent Model Used: {{Agent Model Name/Version}}

### Debug Log References

### Completion Notes List

### File List

## QA Results
