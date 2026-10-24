# Codex++ Ubuntu

Ubuntu build and per-user installation scripts for
[CodexPlusPlus](https://github.com/BigPizzaV3/CodexPlusPlus).

This repository is an Ubuntu integration layer. It does not include the
upstream source tree, compiled binaries, the official ChatGPT application,
or official artwork. The build downloads a pinned upstream tag from GitHub,
compiles it in Docker, and installs the result for the current user.

## License boundary

- Upstream CodexPlusPlus is licensed under `AGPL-3.0-only` and is copyright
  BigPizzaV3.
- This repository is also distributed under AGPL-3.0-only.
- This project is not affiliated with or endorsed by OpenAI, ChatGPT, or Codex.
- Do not commit the official ChatGPT package, `app.asar`, official icons,
  or personal configuration.

See [`LICENSE`](./LICENSE) and [`NOTICE.md`](./NOTICE.md).

## Requirements

- Ubuntu 24.04 or newer
- `git`, `curl`, `tar`, and `sha256sum`
- Docker, with permission for the current user to run it
- The official ChatGPT Desktop Linux package
- Default application path: `/usr/lib/chatgpt`

## Build

Build and verify the pinned Codex++ `v1.5.0` source:

```bash
git clone https://github.com/ZHAO25265/ZHAO25265-Codex-ubuntu.git
cd ZHAO25265-Codex-ubuntu
bash scripts/build-ubuntu.sh
```

The build:

1. Downloads and verifies the upstream `v1.5.0` source archive;
2. Applies versioned patches from `patches/<version>/*.patch` (including the fix preventing `~/.codex/auth.json` from being emptied when switching API providers without a ChatGPT OAuth login);
3. Builds an isolated Ubuntu Docker image and caches Cargo dependencies under `.cache/cargo-home`;
4. Compiles the launcher and manager and runs core relay configuration/switching regression tests (`CODEXPP_RUN_TESTS=1` by default);
5. Keeps generated files under local `build/`, which is ignored by Git.

When changing `UPSTREAM_VERSION`, provide `UPSTREAM_SHA256` and review the
corresponding upstream license, third-party notices, and patch compatibility
before redistribution.

## Install

```bash
bash scripts/install-ubuntu.sh
```

The default install locations are:

- `~/.local/bin/codex-plus-plus`
- `~/.local/bin/codex-plus-plus-manager`
- `~/.local/opt/codex-plus-plus/<version>/`

Re-running `bash scripts/install-ubuntu.sh` safely updates existing symlinks managed under `~/.local/opt/codex-plus-plus/` (while refusing to overwrite unrelated files unless `FORCE_INSTALL=1` is set).

For a non-default official application path:

```bash
CODEX_APP_DIR=/path/to/chatgpt bash scripts/install-ubuntu.sh
```

The installer backs up existing Codex/ChatGPT user configuration under
`~/.local/state/codex-plus-plus/backups/`. It does not upload or commit that
configuration.

## Verify and uninstall

```bash
bash scripts/verify-ubuntu.sh
bash scripts/uninstall-ubuntu.sh
```

Uninstall removes only files installed by this repository and keeps user
configuration and backups by default.
