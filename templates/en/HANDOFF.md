# Session Bootstrap

> Stores the session agent bootstrap prompt.
> This content is stable — every spawned session agent gets the same prompt.
> What changes is CURRENT.md; the session agent reads it after receiving this prompt.

## Session Prompt

```text
Read .project/RULES.md and .project/CURRENT.md.
Check code and Git status against CURRENT.md; report any drift or conflict first.
Pick an executable action from "Next step" and start immediately — do not ask for confirmation on routine steps.
When done, execute the close-out protocol defined in RULES.md:
Update CURRENT.md, run checks, report done/not done/blocked/evidence/next step.
```

## Environment Entry Points

<!-- Fill in key commands for this project -->

Build: `<command>`
Test: `<command>`
Lint: `<command>`
Dev server: `<command>`

## Common Paths

<!-- Directories/files the session agent frequently works with -->

Source entry:
Config:
Tests:
