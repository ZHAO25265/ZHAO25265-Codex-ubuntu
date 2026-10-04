#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_VERSION="${UPSTREAM_VERSION:-1.5.0}"
INSTALL_DIR="${HOME}/.local/opt/codex-plus-plus/${UPSTREAM_VERSION}"
BIN_DIR="${HOME}/.local/bin"
APPLICATION_DIR="${HOME}/.local/share/applications"

for binary in codex-plus-plus codex-plus-plus-manager; do
  link="${BIN_DIR}/${binary}"
  target="${INSTALL_DIR}/${binary}"
  if [[ -L "$link" && "$(readlink -f "$link")" == "$target" ]]; then
    rm -f "$link"
  fi
done

for desktop in \
  "${APPLICATION_DIR}/codex-plus-plus-launcher.desktop" \
  "${APPLICATION_DIR}/codex-plus-plus-manager.desktop"; do
  if [[ -f "$desktop" ]] && grep -qF "${BIN_DIR}/codex-plus-plus" "$desktop"; then
    rm -f "$desktop"
  fi
done

rm -rf "$INSTALL_DIR"

command -v update-desktop-database >/dev/null 2>&1 &&
  update-desktop-database "$APPLICATION_DIR" >/dev/null 2>&1 || true

echo "Removed Codex++ ${UPSTREAM_VERSION} files."
echo "User configuration and backups were preserved."
