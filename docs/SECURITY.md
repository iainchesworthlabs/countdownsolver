# Security policy

## Supported versions

CountdownSolver is pre-1.0. Security fixes land on `develop` and ship in the next
release; only the latest release is supported.

## Reporting a vulnerability

Please **don't** open a public issue for a security vulnerability. Use
GitHub's private reporting instead:
[Report a vulnerability](https://github.com/iainchesworthlabs/countdownsolver/security/advisories/new)
(**Security** tab → **Report a vulnerability**). That opens a private
advisory only maintainers can see, so it can be fixed before details go
public.

Include what you'd include in any good bug report: what you found, how to
reproduce it, and what you think the impact is. A CVE-worthy finding versus
a hardening suggestion are both welcome — if you're unsure which one it is,
report it privately anyway and let's figure it out there.

There's no bounty program, but you can expect an initial response within 14
days — this is a small solo/hobby project, not a funded one, so that's a
response acknowledging the report and starting triage, not necessarily a fix.

## Verifying a release

Every release lists `SHA256SUMS` and `SHA512SUMS` for its files. The checksum
files are signed with Sigstore, and each package has a build provenance
attestation. With the files in one folder:

```sh
sha256sum -c SHA256SUMS
gh attestation verify <file> -R iainchesworthlabs/countdownsolver
cosign verify-blob --bundle SHA256SUMS.sigstore.json \
  --certificate-identity "https://github.com/iainchesworthlabs/countdownsolver/.github/workflows/release.yml@refs/tags/<tag>" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  SHA256SUMS
```

The releases up to `v0.3.0-beta.4` were built while the repository was
`iainchesworth/CountdownSolver`, so for those use `-R iainchesworth/CountdownSolver`
and the identity
`https://github.com/iainchesworth/CountdownSolver/.github/workflows/release.yml@refs/tags/<tag>`.
