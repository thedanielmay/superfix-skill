# Exploration by type

Moved from SKILL.md 1.1.1 (superfix-skill#42); edited in 1.3.0. SKILL.md says when to read this file.

### Exploration by type

These run as evidence collectors inside the diagnosis method in `references/diagnose.md`, under its limits (before approval, `systematic-debugging` and `diagnose` stop after their Phase 3).

**`bug`**
- `superpowers:systematic-debugging` - frames the failure, classifies root cause category [sonnet/high]
- `feature-dev:code-explorer` - traces the affected execution paths [sonnet/high]
- `diagnose` - escalation if `systematic-debugging` cannot identify the root cause category after one pass, or the identified cause is speculative rather than confirmed by code evidence [sonnet/high]

**`performance`**
- `feature-dev:code-explorer` - maps the hot path end-to-end [sonnet/high]
- `grepai-trace-graph` - builds recursive call graph of the slow path [sonnet/high]
- Measure before planning: run actual timing/profiling. Record baseline numbers in ## Problems; the context file copies them in Phase 2.

**`ux`**
- `feature-dev:code-explorer` - reads component tree, design tokens, layout patterns [sonnet/high]
- Note existing impeccable/ui-ux-pro-max conventions already in use

**`architecture`**
- `feature-dev:code-explorer` - full system mapping, data flows, module boundaries [sonnet/high]
- `architecture-deep-dive` - structural analysis, strengths/weaknesses [opus/high]
- `grepai-trace-graph` - dependency graph across subsystems [sonnet/high]
- `improve-codebase-architecture` - identifies shallow modules, structural candidates [sonnet/high]

**`security`**
- `feature-dev:code-explorer` - traces auth flows, data flows, trust boundaries [sonnet/high]
- `code-security-audit` - run on relevant files pre-plan to understand current exposure [sonnet/high]

**`feature` Simple**
- Built-in `Explore` agent - quick symbol/file lookup, "where does this slot in?" - max 5 minutes [haiku/high]

**`feature` Moderate/Complex**
- `feature-dev:code-explorer` - traces where feature integrates [sonnet/high]
- `feature-dev:code-architect` - maps existing patterns, identifies what can be reused [sonnet/high]
