#!/usr/bin/env bash
set -euo pipefail

export HOME="${HOME:-/tmp/codexpp-builder}"
export CARGO_HTTP_TIMEOUT="${CARGO_HTTP_TIMEOUT:-120}"
export CARGO_HTTP_LOW_SPEED_LIMIT="${CARGO_HTTP_LOW_SPEED_LIMIT:-1}"
export CARGO_NET_RETRY="${CARGO_NET_RETRY:-3}"

mkdir -p "$HOME"

cd /source/apps/codex-plus-manager
npm ci --no-audit --no-fund
npm run vite:build

cd /source
cargo \
  --config 'source.crates-io.replace-with="rsproxy"' \
  --config 'source.rsproxy.registry="sparse+https://rsproxy.cn/index/"' \
  build --release --locked \
  -p codex-plus-launcher \
  -p codex-plus-manager

test -x target/release/codex-plus-plus
test -x target/release/codex-plus-plus-manager
