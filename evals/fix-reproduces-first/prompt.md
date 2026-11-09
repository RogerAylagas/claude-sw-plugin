---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, AskUserQuestion, Bash, Write, Edit]
---

average() in src/stats.py raises ZeroDivisionError when it gets an empty list. It should return
0.0 instead. This isn't urgent, it can go out with the next release. Please fix it and commit
the fix; don't push anything.
