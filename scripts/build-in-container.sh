#!/usr/bin/env bash
set -euo pipefail

export HOME="${HOME:-/tmp/codexpp-builder}"
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export CARGO_HTTP_TIMEOUT="${CARGO_HTTP_TIMEOUT:-120}"
export CARGO_HTTP_LOW_SPEED_LIMIT="${CARGO_HTTP_LOW_SPEED_LIMIT:-1}"
export CARGO_NET_RETRY="${CARGO_NET_RETRY:-3}"

mkdir -p "$HOME" "$CARGO_HOME"

cargo_args=()
if [[ -n "${CARGO_REGISTRY_MIRROR:-}" ]]; then
  cargo_args+=(
    --config 'source.crates-io.replace-with="rsproxy"'
    --config "source.rsproxy.registry=\"${CARGO_REGISTRY_MIRROR}\""
  )
fi

cd /source/apps/codex-plus-manager
npm ci --no-audit --no-fund
npm run vite:build

cd /source
cargo "${cargo_args[@]}" \
  build --release --locked \
  -p codex-plus-launcher \
  -p codex-plus-manager

if [[ "${CODEXPP_RUN_TESTS:-1}" == "1" ]]; then
  cargo "${cargo_args[@]}" \
    test --release --locked \
    -p codex-plus-core \
    --test relay_config \
    --test relay_switch
fi

test -x target/release/codex-plus-plus
test -x target/release/codex-plus-plus-manager
