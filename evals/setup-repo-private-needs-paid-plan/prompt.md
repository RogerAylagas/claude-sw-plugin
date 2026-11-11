---
description: When setup-repo asks whether the new GitHub repository is public or private, it says that branch protection on a private repository needs a paid GitHub plan.
tags: [setup-repo]
max_turns: 15
allowed_tools: [Read, Glob, Grep, Bash, AskUserQuestion]
---

/sw:setup-repo python demo-app

This directory is empty. My choices so far: a Python application, uv, the latest Python release
with bugfix support, mypy, MIT license (holder "Eval"), description "Demo app.". There is no
GitHub repository yet. Ask me how to set one up before creating anything.
