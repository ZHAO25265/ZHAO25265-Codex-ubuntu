#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_VERSION="${UPSTREAM_VERSION:-1.5.0}"
UPSTREAM_URL="https://github.com/BigPizzaV3/CodexPlusPlus/archive/refs/tags/v${UPSTREAM_VERSION}.tar.gz"
BUILD_DIR="${ROOT_DIR}/build"
CACHE_DIR="${ROOT_DIR}/.cache"
TARBALL="${CACHE_DIR}/codex-plus-plus-${UPSTREAM_VERSION}.tar.gz"
UPSTREAM_DIR="${BUILD_DIR}/upstream"
IMAGE_NAME="${CODEXPP_BUILDER_IMAGE:-codexpp-builder:ubuntu26}"

mkdir -p "$BUILD_DIR" "$CACHE_DIR"

if [[ ! -f "$TARBALL" ]]; then
  curl --fail --location --retry 3 --output "$TARBALL" "$UPSTREAM_URL"
fi

if [[ "$UPSTREAM_VERSION" == "1.5.0" ]]; then
  expected_sha256="9ed659e5defb217d341ae222f02cf6e0c8c7a02eaae1f10c0f54d1d522544e00"
  actual_sha256="$(sha256sum "$TARBALL" | awk '{print $1}')"
  [[ "$actual_sha256" == "$expected_sha256" ]] || {
    echo "Upstream archive checksum mismatch." >&2
    exit 1
  }
fi

rm -rf "$UPSTREAM_DIR"
mkdir -p "$UPSTREAM_DIR"
tar -xzf "$TARBALL" -C "$UPSTREAM_DIR" --strip-components=1

docker build \
  --tag "$IMAGE_NAME" \
  --file "$ROOT_DIR/docker/codexpp-builder.Dockerfile" \
  "$ROOT_DIR"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp/codexpp-builder \
  --volume "$UPSTREAM_DIR:/source" \
  --volume "$ROOT_DIR/scripts/build-in-container.sh:/usr/local/bin/build-in-container.sh:ro" \
  "$IMAGE_NAME" \
  bash /usr/local/bin/build-in-container.sh

echo "Build complete: $UPSTREAM_DIR/target/release/codex-plus-plus"
echo "Build complete: $UPSTREAM_DIR/target/release/codex-plus-plus-manager"
