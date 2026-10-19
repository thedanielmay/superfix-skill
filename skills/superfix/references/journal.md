# Issue journal

Moved word for word from SKILL.md 1.1.1 (superfix-skill#42). SKILL.md says when to read this file.

When working from a GitHub issue, the issue is the single source of truth for the work. Apply this pattern throughout the pipeline:

**Issue body = living spec/plan**
Keep the issue body current, but never overwrite what the reporter wrote.
- First edit: copy the existing body word for word under a `## Original report` heading at the bottom. Never edit that section afterwards.
- Later edits: if the body already has `## Original report`, keep everything from that heading to the end untouched and rewrite only the sections above it.
- After Phase 0 and after any plan is written or significantly revised, update those sections. They should always answer: "what are we building, why, and what's out of scope?"
- Include the `## Plan` section only when a plan file exists (Moderate and Complex). Simple work has none.

```bash
BODY="$(gh issue view <N> --json body -q .body)"
# Reporter's text: after the heading if it already exists, else the whole body
if printf '%s\n' "$BODY" | grep -q '^## Original report$'; then
  ORIG="$(printf '%s\n' "$BODY" | awk '/^## Original report$/{f=1;next} f')"
else
  ORIG="$BODY"
fi
F="$(mktemp)"
cat > "$F" <<'EOF'
## Summary
<one paragraph: what this is and why>

## Scope
<what is in scope>

## Out of scope
<what is explicitly excluded>

## Key decisions
- <decision 1>
- <decision 2>

## Plan
docs/superpowers/plans/<filename>.md   <!-- only when a plan exists -->
EOF
printf '\n## Original report\n%s\n' "$ORIG" >> "$F"
gh issue edit <N> --body-file "$F"
```

**Progress comments = timestamped changelog**
Each significant phase transition gets a progress comment - not an edit to the body. Comments accumulate as a readable audit trail of what happened and when.

Required progress comment triggers:
- Phase 0 complete: problem profile posted (already required above)
- Phase 1 complete: complexity tier confirmed, key findings summarised
- Phase 2 complete: plan approved after expert panel (already required above)
- Phase 3 complete: implementation done, tests green, PR created (already required in Phase 4)
- Any significant scope change or blocker encountered

Comment format:
```bash
gh issue comment <N> --body "✅ Phase N complete - [one sentence summary of outcome]. Next: [next step]."
```

**This applies only when an issue was referenced.** Freeform-description invocations skip all GitHub journal steps.
