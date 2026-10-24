#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_VERSION="${UPSTREAM_VERSION:-1.5.0}"
INSTALL_DIR="${HOME}/.local/opt/codex-plus-plus/${UPSTREAM_VERSION}"

for binary in codex-plus-plus codex-plus-plus-manager; do
  path="${INSTALL_DIR}/${binary}"
  link="${HOME}/.local/bin/${binary}"
  [[ -x "$path" ]] || {
    echo "Missing executable: $path" >&2
    exit 1
  }
  if ldd "$path" | grep -q 'not found'; then
    echo "Missing shared library for: $path" >&2
    exit 1
  fi
  [[ -x "$link" ]] || {
    echo "Missing launcher symlink: $link" >&2
    exit 1
  }
  if [[ "$(readlink -f "$link")" != "$path" ]]; then
    echo "Symlink target mismatch: $link -> $(readlink -f "$link") (expected $path)" >&2
    exit 1
  fi
done

[[ -f "${INSTALL_DIR}/UPSTREAM-LICENSE" ]]
[[ -f "${INSTALL_DIR}/NOTICE.md" ]]
[[ -f "${HOME}/.local/share/applications/codex-plus-plus-launcher.desktop" ]]
[[ -f "${HOME}/.local/share/applications/codex-plus-plus-manager.desktop" ]]

echo "Codex++ ${UPSTREAM_VERSION} installation checks passed."
