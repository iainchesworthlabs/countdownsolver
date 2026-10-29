# Branch protection and the merge queue

Branch and repository settings can't be expressed as a workflow file. They are rulesets, applied under
**Settings → Rules → Rulesets** by someone with admin rights, from the definitions in
`icl-common-infra` (`admin/apply.sh`) and `.github/repo-settings.json`. This page records what is set so it can be
rebuilt or audited from the page alone.

## The flow

```text
feature/* bugfix/* docs/* chore/* ──PR──▶ merge queue ──▶ develop ──tag──▶ main
```

- A pull request targets `develop`. When it is ready and its required checks pass, it is put in the merge queue,
  which builds it with the entries ahead of it and squash merges it. Nobody pushes to `develop` or merges by hand.
- `main` only holds releases. The release workflow moves it to the tagged commit with the release bot's token; no
  pull request is used.
- A head branch is deleted when its pull request merges. The squash commit takes the pull request's title and body.

## Rulesets

| Ruleset | Applies to | Rules |
|---|---|---|
| `branch-names` | creating a branch | Only `develop`, `main`, `feature/**`, `bugfix/**`, `docs/**`, `chore/**`, `agent/**`, `release/**`, `dependabot/**`, `gh-readonly-queue/**` and `gh-pages` can be created. |
| `develop-protection` | `develop` | No deletion or force push; linear history; a pull request is required (no approvals needed while there is one maintainer, stale approvals dismissed, conversations resolved, squash only); the checks `CI Status` and `Scan dependency diff` must pass. No bypass. |
| `merge-queue-develop` | `develop` | Merge queue, squash, all entries green, up to four builds at once. |
| `main-release-only` | `main` | Only the release bot can update it; no deletion or force push. |
| `tags` | `v*` tags | Tags can't be deleted, moved or re-created; only the owner and the release bot can create one. |

`CI Status` is the one job that stands for the whole build matrix, coverage gate, CodeQL and static checks
(see `ci.md`), so the list of required checks does not change when a leg is added. `Scan dependency diff` fails on
a moderate-or-worse known vulnerability a pull request adds in `vcpkg.json` or an Actions dependency.

## Other scanners (visible-only)

`osv-scanner.yml`, `zizmor.yml`, and `scorecard.yml` upload SARIF to
**Security → Code scanning** but don't fail PR checks — triage their alerts
there rather than via a required status check (see each workflow's header
comment for why). `scorecard.yml`'s branch-protection sub-check scores more
completely with a fine-grained PAT (read-only, "Administration: read") added
as a repo secret named `SCORECARD_READ_TOKEN`; without it, that one
sub-check just degrades gracefully instead of failing.
