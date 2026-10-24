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
ICON_THEME_DIR="${HOME}/.local/share/icons/hicolor"
ICON_DIR="${ICON_THEME_DIR}/128x128/apps"
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

umask 022
mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$APPLICATION_DIR" "$ICON_DIR"
chmod 755 "$INSTALL_ROOT" "$INSTALL_DIR" "$BIN_DIR" "$APPLICATION_DIR" \
  "$ICON_THEME_DIR" "${ICON_THEME_DIR}/128x128" "$ICON_DIR" 2>/dev/null || true

if [[ "${SKIP_BACKUP:-0}" != "1" ]]; then
  (
    umask 077
    mkdir -p "$BACKUP_DIR"
    if [[ -d "${HOME}/.codex" ]]; then
      tar --exclude='*.sock' --exclude='*.lock' \
        -czf "${BACKUP_DIR}/codex-config.tar.gz" -C "$HOME" .codex
    fi
    if [[ -d "${HOME}/.config/Codex" ]]; then
      tar --exclude='*.sock' --exclude='*.lock' \
        -czf "${BACKUP_DIR}/chatgpt-config.tar.gz" -C "$HOME" .config/Codex
    fi
  )
fi

install -m755 "${UPSTREAM_DIR}/target/release/codex-plus-plus" \
  "${INSTALL_DIR}/codex-plus-plus"
install -m755 "${UPSTREAM_DIR}/target/release/codex-plus-plus-manager" \
  "${INSTALL_DIR}/codex-plus-plus-manager"
install -m644 "${UPSTREAM_DIR}/LICENSE" "${INSTALL_DIR}/UPSTREAM-LICENSE"
install -m644 "${ROOT_DIR}/NOTICE.md" "${INSTALL_DIR}/NOTICE.md"
if [[ -f "${UPSTREAM_DIR}/apps/codex-plus-manager/src-tauri/icons/icon.png" ]]; then
  install -m644 "${UPSTREAM_DIR}/apps/codex-plus-manager/src-tauri/icons/icon.png" \
    "${ICON_DIR}/codex-plus-plus.png"
  install -m644 "${UPSTREAM_DIR}/apps/codex-plus-manager/src-tauri/icons/icon.png" \
    "${ICON_DIR}/codex-plus-plus-manager.png"
fi
if [[ -d "${ROOT_DIR}/patches/${UPSTREAM_VERSION}" ]]; then
  shopt -s nullglob
  patch_files=("${ROOT_DIR}/patches/${UPSTREAM_VERSION}"/*.patch)
  if (( ${#patch_files[@]} > 0 )); then
    mkdir -p "${INSTALL_DIR}/patches"
    chmod 755 "${INSTALL_DIR}/patches"
    install -m644 "${patch_files[@]}" "${INSTALL_DIR}/patches/"
  fi
  shopt -u nullglob
fi
ln -sfn "${INSTALL_DIR}/codex-plus-plus" "${BIN_DIR}/codex-plus-plus"
ln -sfn "${INSTALL_DIR}/codex-plus-plus-manager" "${BIN_DIR}/codex-plus-plus-manager"

launcher_icon="applications-development"
manager_icon="preferences-system"
if [[ -f "${ICON_DIR}/codex-plus-plus.png" ]]; then
  launcher_icon="${ICON_DIR}/codex-plus-plus.png"
fi
if [[ -f "${ICON_DIR}/codex-plus-plus-manager.png" ]]; then
  manager_icon="${ICON_DIR}/codex-plus-plus-manager.png"
fi

# 先写入临时文件再原子替换，避免 gnome-shell 监听到 0 字节截断导致应用从应用栏消失。
launcher_tmp="${APPLICATION_DIR}/.codex-plus-plus-launcher.desktop.tmp"
cat > "${launcher_tmp}" <<EOF
[Desktop Entry]
Name=Codex++
Comment=Ubuntu launcher for CodexPlusPlus
Exec=${BIN_DIR}/codex-plus-plus --app-path "${CODEX_APP_DIR}"
TryExec=${BIN_DIR}/codex-plus-plus
Icon=${launcher_icon}
Type=Application
Categories=Development;
Terminal=false
StartupNotify=true
EOF
chmod 644 "${launcher_tmp}"
mv -f "${launcher_tmp}" "${APPLICATION_DIR}/codex-plus-plus-launcher.desktop"

manager_tmp="${APPLICATION_DIR}/.codex-plus-plus-manager.desktop.tmp"
cat > "${manager_tmp}" <<EOF
[Desktop Entry]
Name=Codex++ Manager
Comment=Ubuntu manager for CodexPlusPlus
Exec=${BIN_DIR}/codex-plus-plus-manager
TryExec=${BIN_DIR}/codex-plus-plus-manager
Icon=${manager_icon}
Type=Application
Categories=Development;
Terminal=false
StartupNotify=true
StartupWMClass=codex-plus-plus-manager
EOF
chmod 644 "${manager_tmp}"
mv -f "${manager_tmp}" "${APPLICATION_DIR}/codex-plus-plus-manager.desktop"

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "${APPLICATION_DIR}/codex-plus-plus-launcher.desktop"
  desktop-file-validate "${APPLICATION_DIR}/codex-plus-plus-manager.desktop"
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$ICON_THEME_DIR" >/dev/null 2>&1 || true
  [[ -f "${ICON_THEME_DIR}/icon-theme.cache" ]] && chmod 644 "${ICON_THEME_DIR}/icon-theme.cache" || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPLICATION_DIR" >/dev/null 2>&1 || true
  [[ -f "${APPLICATION_DIR}/mimeinfo.cache" ]] && chmod 644 "${APPLICATION_DIR}/mimeinfo.cache" || true
fi

# 若当前处于 GNOME 桌面会话，确保 Codex++ 与 Codex++ Manager 固定在应用栏（Ubuntu Dock）并触发刷新。
if command -v gsettings >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
  if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" && -S "/run/user/$(id -u)/bus" ]]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
  fi
  python3 - <<'PY' 2>/dev/null || true
import ast, subprocess
raw = subprocess.check_output(
    ["gsettings", "get", "org.gnome.shell", "favorite-apps"],
    text=True,
).strip()
if raw.startswith("@as "):
    raw = raw[4:].strip()
favs = list(ast.literal_eval(raw))
for entry in ["codex-plus-plus-manager.desktop", "codex-plus-plus-launcher.desktop"]:
    if entry not in favs:
        favs.append(entry)
without = [x for x in favs if x not in ("codex-plus-plus-manager.desktop", "codex-plus-plus-launcher.desktop")]
subprocess.run(["gsettings", "set", "org.gnome.shell", "favorite-apps", repr(without)], check=False)
subprocess.run(["gsettings", "set", "org.gnome.shell", "favorite-apps", repr(favs)], check=False)
PY
fi

echo "Installed Codex++ ${UPSTREAM_VERSION}."
echo "Backup: ${BACKUP_DIR}"
echo "Launcher: ${BIN_DIR}/codex-plus-plus"
echo "Manager: ${BIN_DIR}/codex-plus-plus-manager"
