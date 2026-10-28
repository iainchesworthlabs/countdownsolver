# Installing

Every [tagged release](https://github.com/iainchesworthlabs/countdownsolver/releases)
publishes prebuilt packages for Windows, macOS, and Linux (see
[Building & packaging](building.md#packaging)) plus Android. Each Release page
also gets an **Install** section with a working link, generated automatically —
this page explains what that link does and the steps around it.

## Android

1. Open the release's **Install** section (or its **Assets** list) and
   download `CountdownSolver-<version>-android-arm64-v8a.apk`.
2. Android blocks installs from outside Google Play by default. When you
   open the downloaded file you'll be prompted to allow it — either via a
   one-time "Install unknown apps" prompt, or in advance under
   **Settings → Apps → Special app access → Install unknown apps**, choose
   the app you downloaded with (browser or Files), and enable it.
3. Open the `.apk` again and confirm the install prompt.

The signed APK comes from `release.yml`'s `android-release` job — see
[CI & dependencies](ci.md#signed-mobile-release-packaging) for how it's
built and signed.

## iOS

iOS is not published from a release. The app builds for iPhone and iPad in CI,
and testing on devices will go through TestFlight to invited testers.

## Verifying a download

Every release publishes `SHA256SUMS`/`SHA512SUMS` covering every asset
each Sigstore-attested at build time and the
combined manifests cosign-signed at publish time:

```sh
sha256sum -c SHA256SUMS
gh attestation verify CountdownSolver-android-arm64-v8a.apk -R iainchesworthlabs/countdownsolver
```

See [Building & packaging → Packaging](building.md#packaging) for details.
