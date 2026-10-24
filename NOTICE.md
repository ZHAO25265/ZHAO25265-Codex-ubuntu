# Notices

## Project scope

This repository is an Ubuntu packaging and installation layer for
[CodexPlusPlus](https://github.com/BigPizzaV3/CodexPlusPlus).
It does not contain the upstream source tree, compiled binaries, official
desktop application files, or official application artwork.

CodexPlusPlus is copyright BigPizzaV3 and is licensed under
`AGPL-3.0-only`. The upstream license and notices apply to the upstream
source downloaded by the build script.

The packaging and integration scripts in this repository are distributed
under the repository license. They are not affiliated with or endorsed by
OpenAI, ChatGPT, or Codex.

OpenAI, ChatGPT, and Codex are trademarks or product names belonging to
their respective owners. This repository does not grant rights to use
those trademarks, official application assets, or official branding.

## Upstream modifications

When `patches/<version>/*.patch` exists, `scripts/build-ubuntu.sh` applies those
patches to the extracted upstream source archive before building. All patches in
this repository are distributed under `AGPL-3.0-only` and are also installed to
`~/.local/opt/codex-plus-plus/<version>/patches/`.

- `patches/1.5.0/0001-fix-provider-switch-auth-login-fallback.patch` (2026-10-24):
  Fix provider switching to `Official + official_mix_api_key` / `MixedApi`
  profiles when no ChatGPT OAuth `tokens` login exists in `~/.codex/auth.json`.
  Instead of stripping `OPENAI_API_KEY` and writing an empty 0-byte `auth.json`
  (which causes Codex to enter the login screen on launch), preserve/write the
  target provider's API key into `auth.json` and add startup self-healing for
  empty `auth.json` in both the launcher and manager.

## Third-party notices

The upstream project includes its own third-party notices, including
components under the MIT License. Review the upstream
[`THIRD_PARTY_NOTICES.md`](https://github.com/BigPizzaV3/CodexPlusPlus/blob/main/THIRD_PARTY_NOTICES.md)
when redistributing a built upstream copy.
