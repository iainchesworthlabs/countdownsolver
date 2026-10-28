# FAQ / troubleshooting

Quick answers, linking out to the full detail rather than repeating it.

**I switched the language in Settings — does that change gameplay too, or
just the menus?**
Both. Letters and Conundrum solve against that language's own dictionary
and alphabet rules, not just translated labels — see
[How to play → Languages](how-to-play.md#languages). Numbers is
language-independent (it's arithmetic).

**I unzipped the Linux build and the app won't start.**
The Linux packages carry their own Qt, so a missing Qt is not the cause. Run
`usr/bin/countdownsolver` from the unpacked folder. It needs the X11 and
OpenGL libraries a desktop normally has (the `.deb` lists them), and glibc 2.39
or newer. See [Building & packaging → Supported platforms](building.md#supported-platforms).

**`apt install` refuses the `.deb` package.**
The `.deb` needs glibc 2.39 or newer, which is Ubuntu 24.04 and Debian 13 and
later. On an older system, build from source ([Getting started](getting-started.md)).

**My custom word list isn't showing up.**
Drop a newline-delimited word list at `<config-dir>/words.txt` (the exact
path is shown in **Settings**) and **restart the app** — it's only read
at startup. See
[Getting started → Using your own word list](getting-started.md#using-your-own-word-list).

**Is there an Android or iOS download?**
Android, yes — every [release](https://github.com/iainchesworthlabs/countdownsolver/releases)
from `v0.2.0-beta.1` on ships a signed APK/AAB, covering tablet and phone
in both portrait and landscape. iOS builds successfully in CI and targets
iPhone and iPad in all orientations, but it is not published from a release:
testing on devices will go through TestFlight. See
[Building & packaging → Supported platforms](building.md#supported-platforms).

**My PR is failing the "Translations complete" / "Check translations are
up to date" CI check.**
You changed or added a translatable string without updating the `.ts`
files, or left one marked unfinished. See [Translations](translations.md).

**Where do I report a security vulnerability?**
Not as a public issue — see [Security policy](https://github.com/iainchesworth/CountdownSolver/security/policy)
for private reporting.

Didn't find your issue here? [Open one](https://github.com/iainchesworth/CountdownSolver/issues/new/choose) —
see [Contributing](CONTRIBUTING.md) first if it's more than a quick
question.
