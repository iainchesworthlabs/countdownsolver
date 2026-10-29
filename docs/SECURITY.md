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

Every release lists `SHA512SUMS`, a detached GPG signature (`.asc`) for every file and for
`SHA512SUMS`, an SBOM (`sbom.spdx.json`), and a build provenance attestation for every file.
The public key is committed as [`docs/signing-key.asc`](https://github.com/iainchesworthlabs/countdownsolver/blob/main/docs/signing-key.asc).
With the release files in one folder:

```sh
gpg --import signing-key.asc
gpg --verify SHA512SUMS.asc SHA512SUMS
sha512sum -c SHA512SUMS
gh attestation verify <file> -R iainchesworthlabs/countdownsolver
```

`gpg --show-keys signing-key.asc` prints the key's fingerprint, which should be:

```text
FD13 CB8C AC83 1664 8CD9  74D0 8149 254C 4189 4DBE
```

The key expires on 2028-10-21.

The releases up to `v0.3.0-beta.4` were built before this and were signed with Sigstore instead:
they list `SHA256SUMS` and `SHA512SUMS` with a `.sigstore.json` bundle. They were built while the
repository was `iainchesworth/CountdownSolver`, so for those use `-R iainchesworth/CountdownSolver` and:

```sh
sha256sum -c SHA256SUMS
cosign verify-blob --bundle SHA256SUMS.sigstore.json \
  --certificate-identity "https://github.com/iainchesworth/CountdownSolver/.github/workflows/release.yml@refs/tags/<tag>" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  SHA256SUMS
```
