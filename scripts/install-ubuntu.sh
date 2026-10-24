#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_VERSION="${UPSTREAM_VERSION:-1.5.0}"
CODEX_APP_DIR="${CODEX_APP_DIR:-/usr/lib/chatgpt}"
UPSTREAM_DIR="${ROOT_DIR}/build/upstream"
INSTALL_ROOT="${HOME}/.local/opt/codex-plus-plus"
INSTALL_DIR="${INSTALL_ROOT}/${UPSTREAM_VERSION}"
BIN_DIR="${HOME}/.local/bin"
APPLICATION_DIR="${HOME}/.local/share/applications"
BACKUP_DIR="${HOME}/.local/state/codex-plus-plus/backups/$(date +%Y%m%d-%H%M%S)"

[[ -x "${UPSTREAM_DIR}/target/release/codex-plus-plus" ]] || {
  echo "Run scripts/build-ubuntu.sh first." >&2
  exit 1
}
[[ -x "${UPSTREAM_DIR}/target/release/codex-plus-plus-manager" ]] || {
  echo "Run scripts/build-ubuntu.sh first." >&2
  exit 1
}
[[ -x "${CODEX_APP_DIR}/ChatGPT" ]] || {
  echo "ChatGPT executable not found: ${CODEX_APP_DIR}/ChatGPT" >&2
  exit 1
}
[[ "${CODEX_APP_DIR}" != *'"'* ]] || {
  echo 'CODEX_APP_DIR must not contain double quotes.' >&2
  exit 1
}

for binary in codex-plus-plus codex-plus-plus-manager; do
  target_link="${BIN_DIR}/${binary}"
  if [[ -L "${target_link}" ]]; then
    existing_target="$(readlink "${target_link}")"
    if [[ "${existing_target}" != "${INSTALL_ROOT}/"* && "${FORCE_INSTALL:-0}" != "1" ]]; then
      echo "Refusing to overwrite non-Codex++ symlink ${target_link} -> ${existing_target} (set FORCE_INSTALL=1 to override)." >&2
      exit 1
    fi
  elif [[ -e "${target_link}" && "${FORCE_INSTALL:-0}" != "1" ]]; then
    echo "Refusing to overwrite existing ${target_link} (set FORCE_INSTALL=1 to override)." >&2
    exit 1
  fi
done

mkdir -p "$BACKUP_DIR" "$INSTALL_DIR" "$BIN_DIR" "$APPLICATION_DIR"

if [[ -d "${HOME}/.codex" ]]; then
  tar --exclude='*.sock' --exclude='*.lock' \
    -czf "${BACKUP_DIR}/codex-config.tar.gz" -C "$HOME" .codex
fi
if [[ -d "${HOME}/.config/Codex" ]]; then
  tar --exclude='*.sock' --exclude='*.lock' \
    -czf "${BACKUP_DIR}/chatgpt-config.tar.gz" -C "$HOME" .config/Codex
fi

install -m755 "${UPSTREAM_DIR}/target/release/codex-plus-plus" \
  "${INSTALL_DIR}/codex-plus-plus"
install -m755 "${UPSTREAM_DIR}/target/release/codex-plus-plus-manager" \
  "${INSTALL_DIR}/codex-plus-plus-manager"
install -m644 "${UPSTREAM_DIR}/LICENSE" "${INSTALL_DIR}/UPSTREAM-LICENSE"
install -m644 "${ROOT_DIR}/NOTICE.md" "${INSTALL_DIR}/NOTICE.md"
if [[ -d "${ROOT_DIR}/patches/${UPSTREAM_VERSION}" ]]; then
  shopt -s nullglob
  patch_files=("${ROOT_DIR}/patches/${UPSTREAM_VERSION}"/*.patch)
  if (( ${#patch_files[@]} > 0 )); then
    mkdir -p "${INSTALL_DIR}/patches"
    install -m644 "${patch_files[@]}" "${INSTALL_DIR}/patches/"
  fi
  shopt -u nullglob
fi
ln -sfn "${INSTALL_DIR}/codex-plus-plus" "${BIN_DIR}/codex-plus-plus"
ln -sfn "${INSTALL_DIR}/codex-plus-plus-manager" "${BIN_DIR}/codex-plus-plus-manager"

cat > "${APPLICATION_DIR}/codex-plus-plus-launcher.desktop" <<EOF
[Desktop Entry]
Name=Codex++
Comment=Ubuntu launcher for CodexPlusPlus
Exec=${BIN_DIR}/codex-plus-plus --app-path "${CODEX_APP_DIR}"
Icon=applications-development
Type=Application
Categories=Development;
Terminal=false
StartupNotify=true
EOF

cat > "${APPLICATION_DIR}/codex-plus-plus-manager.desktop" <<EOF
[Desktop Entry]
Name=Codex++ Manager
Comment=Ubuntu manager for CodexPlusPlus
Exec=${BIN_DIR}/codex-plus-plus-manager
Icon=preferences-system
Type=Application
Categories=Development;
Terminal=false
StartupNotify=true
EOF

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "${APPLICATION_DIR}/codex-plus-plus-launcher.desktop"
  desktop-file-validate "${APPLICATION_DIR}/codex-plus-plus-manager.desktop"
fi
command -v update-desktop-database >/dev/null 2>&1 &&
  update-desktop-database "$APPLICATION_DIR" >/dev/null 2>&1 || true

echo "Installed Codex++ ${UPSTREAM_VERSION}."
echo "Backup: ${BACKUP_DIR}"
echo "Launcher: ${BIN_DIR}/codex-plus-plus"
echo "Manager: ${BIN_DIR}/codex-plus-plus-manager"
