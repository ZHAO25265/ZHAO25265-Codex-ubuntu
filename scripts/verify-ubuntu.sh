#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_VERSION="${UPSTREAM_VERSION:-1.5.0}"
INSTALL_DIR="${HOME}/.local/opt/codex-plus-plus/${UPSTREAM_VERSION}"

for binary in codex-plus-plus codex-plus-plus-manager; do
  path="${INSTALL_DIR}/${binary}"
  [[ -x "$path" ]] || {
    echo "Missing executable: $path" >&2
    exit 1
  }
  if ldd "$path" | grep -q 'not found'; then
    echo "Missing shared library for: $path" >&2
    exit 1
  fi
done

[[ -x "${HOME}/.local/bin/codex-plus-plus" ]]
[[ -x "${HOME}/.local/bin/codex-plus-plus-manager" ]]
[[ -f "${HOME}/.local/share/applications/codex-plus-plus-launcher.desktop" ]]
[[ -f "${HOME}/.local/share/applications/codex-plus-plus-manager.desktop" ]]

echo "Codex++ ${UPSTREAM_VERSION} installation checks passed."
