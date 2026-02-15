# RALPH Checkpoint

**Generated:** {{TIMESTAMP}}
**Session:** {{SESSION_ID}}
**Loop:** {{LOOP_NAME}}
**Stage:** {{CURRENT_STAGE}} ({{STAGE_NUMBER}}/{{TOTAL_STAGES}})

## Completed Work

### Previous Stages
{{#COMPLETED_STAGES}}
- [x] {{STAGE_NAME}}: {{COMPLETION_SUMMARY}}
{{/COMPLETED_STAGES}}

### Current Stage Progress
{{CURRENT_STAGE_WORK}}

## Next Stage

**Stage Name:** {{NEXT_STAGE}}
**Objectives:**
{{#NEXT_STAGE_OBJECTIVES}}
- [ ] {{OBJECTIVE}}
{{/NEXT_STAGE_OBJECTIVES}}

## Context

**Files Modified:**
{{FILES_MODIFIED}}

**File Tree Hash:** {{FILE_TREE_HASH}}

**Key Decisions:**
{{KEY_DECISIONS}}

## Open Questions / Blockers
{{OPEN_QUESTIONS}}

## Notes
{{NOTES}}

---
*Resume with: `/ralph-resume`*
