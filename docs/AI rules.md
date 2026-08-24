# AI rules.md

Rules for using an LLM (Claude Code, Cursor, Copilot, ChatGPT, etc.) to build this project. The brief explicitly allows any LLM — this file exists so AI assistance produces code that still satisfies the grading rubric (clean architecture, correctness, commit hygiene) rather than fast-but-generic output. Keep this file itself lean; add to it as real mistakes happen, per your usual practice — don't front-load speculative rules.

## 1. Ground Rules
- Never let the assistant invent scope beyond the 4 features and the fixed 10-symbol universe in Trading_feat.txt. If it suggests extras (charts, auth, multi-user), decline unless it's free and doesn't risk the deadline.
- Always point the assistant at PRD.md / TRD.md / Architecture.md / App Flow.md for context rather than re-explaining requirements from scratch each session — paste or reference the relevant doc section.
- The assistant must never introduce a setup step beyond `flutter pub get && flutter run`. If it proposes `build_runner`/codegen, either commit the generated output or reject the suggestion (see TRD.md §2).

## 2. Money & Correctness (non-negotiable)
- Reject any AI-suggested code that uses raw `double` for price × quantity comparisons gating an order. Money math must go through the `Money` type (int minor-units or `Decimal`).
- Reject any suggestion to bind live price to a list *index* instead of *symbol* — this breaks the "reorder keeps correct price binding" requirement. Always key by symbol.
- When the assistant proposes DB writes for order submission, verify it wraps wallet update + holding upsert + order insert in a single transaction, not three separate calls.

## 3. Realtime/Performance
- Any AI-generated widget that consumes `priceProvider` must be scoped as narrowly as possible (row/cell-level `ref.watch`, not screen-level). Reject broad `Consumer`/`setState` patterns that would rebuild an entire list on every tick.
- Ask the assistant to explain *why* a given rebuild is scoped correctly if it's not obvious — don't accept realtime code you can't personally justify to an evaluator.

## 4. Workflow with Claude Code Specifically
- Use **Plan Mode** before any multi-file change (new feature, refactor) — review the plan against Architecture.md before letting it execute.
- Keep context hygiene: start a fresh session per major checkpoint (per Implementation Plan.md's day-by-day commits) rather than one long, drifting session — reduces the chance of the assistant "forgetting" earlier architectural decisions.
- Commit after each checkpoint the assistant completes, with a message describing what changed and why — don't let the assistant batch multiple unrelated changes into one commit (this project is graded partly on commit history).

## 5. Review Checklist Before Accepting Any AI-Generated Diff
- [ ] Does it match the folder structure in Architecture.md, or is there a good reason to deviate (and did the assistant say why)?
- [ ] Does it avoid `double` for money comparisons?
- [ ] Does it key price/state by symbol, not index or position?
- [ ] Does it avoid adding a new dependency without a stated reason?
- [ ] Does it avoid unnecessary rebuilds (spot-check with Flutter DevTools if unsure)?
- [ ] Is error/edge-case handling explicit, not silently swallowed?

## 6. Known Failure Pattern to Watch For (personal note)
When using AI tools for writing/planning tasks generally, there's a tendency to keep generating new structures/angles instead of committing to and finishing one — treat any AI suggestion to "restructure the plan" or "try a different architecture" mid-build with suspicion once Architecture.md is locked. Default to finishing the current plan; only deviate for a concrete, demonstrated blocker, not a stylistic preference surfacing mid-session.

## 7. What NOT to Ask the AI to Do
- Don't ask it to fabricate test results or claim scenarios were verified when they weren't — run the Implementation Plan.md checklist manually yourself before submission.
- Don't have it write the README claiming features work that weren't actually tested end-to-end.
