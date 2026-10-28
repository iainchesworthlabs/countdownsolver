# Changelog fragments

A pull request that changes what a person using the program can see adds one file here, named
`<slug>.<type>.md`, where `<type>` is `added`, `changed`, `deprecated`, `removed`, `fixed` or
`security`. The content is one paragraph that starts with a bold summary:

```markdown
**The theme is remembered.** The theme chosen in Settings is restored the next time the app starts.
```

Do not edit `CHANGELOG.md`. At release time `changelog_tool.py assemble` (in `icl-common-infra`)
moves the fragments into a new section and deletes them. A pull request that changes only
documentation, tests or tooling needs no fragment, and carries the `no-changelog` label instead.
