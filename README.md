# Codex++ Ubuntu

面向 Ubuntu 的 Codex++ 构建与用户级安装脚本。

本仓库是 [CodexPlusPlus](https://github.com/BigPizzaV3/CodexPlusPlus)
的 Ubuntu 适配层，不包含上游完整源码、编译产物、官方 ChatGPT 应用文件或官方 Logo。
构建时会从上游 GitHub tag 下载指定版本，在 Docker 容器中编译，再安装到当前用户目录。

## 许可证边界

- CodexPlusPlus 上游项目采用 `AGPL-3.0-only`，版权归 BigPizzaV3。
- 本仓库整体采用 AGPL-3.0-only，详见 [`LICENSE`](./LICENSE) 和 [`NOTICE.md`](./NOTICE.md)。
- 本项目不是 OpenAI、ChatGPT 或 Codex 官方项目。
- 不要把官方 ChatGPT 安装包、`app.asar`、官方图标或个人配置提交到仓库。

## 系统要求

- Ubuntu 24.04 或更新版本
- `git`、`curl`、`tar`、`sha256sum`
- Docker，并允许当前用户运行 Docker
- 已安装官方 ChatGPT Desktop Linux 包
- 默认官方应用路径：`/usr/lib/chatgpt`

## 构建

默认构建并验证 Codex++ `v1.5.0`：

```bash
git clone https://github.com/ZHAO25265/ZHAO25265-Codex-ubuntu.git
cd ZHAO25265-Codex-ubuntu
bash scripts/build-ubuntu.sh
```

构建脚本会：

1. 下载并校验上游 `v1.5.0` 源码归档（支持断点安全的临时文件下载与强制 SHA-256 校验）；
2. 自动按序应用 `patches/<version>/*.patch` 中的 Ubuntu 修复补丁（包含切换 API 供应商后无 ChatGPT OAuth 登录态时避免清空 `~/.codex/auth.json` 导致进入登录页的修复）；
3. 构建隔离的 Ubuntu Docker 编译环境并复用 `.cache/cargo-home` 依赖缓存；
4. 编译 Codex++ launcher 和 manager，并默认运行核心配置与供应商切换回归测试；
5. 将构建目录保留在本地 `build/`，不会提交到 Git。

可选构建环境变量：

- `CARGO_REGISTRY_MIRROR`：默认使用 `sparse+https://rsproxy.cn/index/`，设为空字符串（`CARGO_REGISTRY_MIRROR=""`）可直连 `crates.io`；
- `CODEXPP_RUN_TESTS`：默认为 `1`，设为 `0` 可跳过容器内回归测试；
- `UPSTREAM_VERSION` / `UPSTREAM_SHA256`：如需构建其他上游版本，必须同时提供 `UPSTREAM_SHA256` 并检查对应版本的许可证、第三方声明和补丁兼容性：

```bash
UPSTREAM_VERSION=1.5.0 bash scripts/build-ubuntu.sh
```

## 安装

```bash
bash scripts/install-ubuntu.sh
```

默认安装位置：

- `~/.local/bin/codex-plus-plus`
- `~/.local/bin/codex-plus-plus-manager`
- `~/.local/opt/codex-plus-plus/<version>/`

重复运行 `bash scripts/install-ubuntu.sh` 会自动更新已指向 `~/.local/opt/codex-plus-plus/` 的软链接（若目标位置存在非 Codex++ 的同名文件，脚本会拒绝覆盖，可通过 `FORCE_INSTALL=1` 强制替换）。

如果官方应用不在默认位置：

```bash
CODEX_APP_DIR=/path/to/chatgpt bash scripts/install-ubuntu.sh
```

安装脚本会先备份已有的 Codex/ChatGPT 用户配置到
`~/.local/state/codex-plus-plus/backups/`，不会把配置上传或提交到 Git。

安装后可以从应用菜单打开 `Codex++` 或 `Codex++ Manager`，也可以运行：

```bash
~/.local/bin/codex-plus-plus
~/.local/bin/codex-plus-plus-manager
```

## 验证与卸载

```bash
bash scripts/verify-ubuntu.sh
bash scripts/uninstall-ubuntu.sh
```

卸载脚本只移除本仓库安装的程序和桌面入口，默认保留用户配置和备份。

## 安全说明

Codex++ 依赖官方桌面应用的页面结构、CDP 行为和本地数据格式。官方应用更新后，
注入功能可能需要适配。使用前请确认你理解上游项目及其许可证，并保留自己的配置备份。
