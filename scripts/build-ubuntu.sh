#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_VERSION="${UPSTREAM_VERSION:-1.5.0}"
UPSTREAM_URL="https://github.com/BigPizzaV3/CodexPlusPlus/archive/refs/tags/v${UPSTREAM_VERSION}.tar.gz"
BUILD_DIR="${ROOT_DIR}/build"
CACHE_DIR="${ROOT_DIR}/.cache"
TARBALL="${CACHE_DIR}/codex-plus-plus-${UPSTREAM_VERSION}.tar.gz"
UPSTREAM_DIR="${BUILD_DIR}/upstream"
PATCH_DIR="${ROOT_DIR}/patches/${UPSTREAM_VERSION}"
CARGO_CACHE_DIR="${CACHE_DIR}/cargo-home"
IMAGE_NAME="${CODEXPP_BUILDER_IMAGE:-codexpp-builder:ubuntu26}"
# 留空则直接使用 crates.io；默认沿用 rsproxy 镜像以兼容国内网络。
CARGO_REGISTRY_MIRROR="${CARGO_REGISTRY_MIRROR-sparse+https://rsproxy.cn/index/}"

case "$UPSTREAM_VERSION" in
  1.5.0) expected_sha256="9ed659e5defb217d341ae222f02cf6e0c8c7a02eaae1f10c0f54d1d522544e00" ;;
  *) expected_sha256="${UPSTREAM_SHA256:-}" ;;
esac
if [[ -z "$expected_sha256" ]]; then
  echo "UPSTREAM_SHA256 is required when building unpinned version ${UPSTREAM_VERSION}." >&2
  exit 1
fi

for tool in curl tar sha256sum patch docker; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "Missing required tool: ${tool}" >&2
    exit 1
  }
done

mkdir -p "$BUILD_DIR" "$CACHE_DIR" "$CARGO_CACHE_DIR"

if [[ ! -f "$TARBALL" ]]; then
  # 先下载到临时文件，避免中断后留下损坏的缓存。
  partial="${TARBALL}.partial"
  rm -f "$partial"
  curl --fail --location --retry 3 --output "$partial" "$UPSTREAM_URL"
  mv "$partial" "$TARBALL"
fi

actual_sha256="$(sha256sum "$TARBALL" | awk '{print $1}')"
if [[ "$actual_sha256" != "$expected_sha256" ]]; then
  echo "Upstream archive checksum mismatch: ${TARBALL}" >&2
  echo "Expected ${expected_sha256}, got ${actual_sha256}. Delete the file and retry." >&2
  exit 1
fi

rm -rf "$UPSTREAM_DIR"
mkdir -p "$UPSTREAM_DIR"
tar -xzf "$TARBALL" -C "$UPSTREAM_DIR" --strip-components=1

# Ubuntu 适配补丁：修改后的源码与补丁本身一同按 AGPL-3.0-only 公开。
if [[ -d "$PATCH_DIR" ]]; then
  shopt -s nullglob
  for patch_file in "$PATCH_DIR"/*.patch; do
    echo "Applying $(basename "$patch_file")"
    patch --directory="$UPSTREAM_DIR" --strip=1 --forward --batch \
      --no-backup-if-mismatch --quiet --input="$patch_file"
  done
  shopt -u nullglob
else
  echo "No Ubuntu patches for ${UPSTREAM_VERSION}; building upstream as-is." >&2
fi

docker build \
  --tag "$IMAGE_NAME" \
  --file "$ROOT_DIR/docker/codexpp-builder.Dockerfile" \
  "$ROOT_DIR"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp/codexpp-builder \
  --env CARGO_HOME=/cargo-home \
  --env CARGO_REGISTRY_MIRROR="$CARGO_REGISTRY_MIRROR" \
  --env CODEXPP_RUN_TESTS="${CODEXPP_RUN_TESTS:-1}" \
  --volume "$UPSTREAM_DIR:/source" \
  --volume "$CARGO_CACHE_DIR:/cargo-home" \
  --volume "$ROOT_DIR/scripts/build-in-container.sh:/usr/local/bin/build-in-container.sh:ro" \
  "$IMAGE_NAME" \
  bash /usr/local/bin/build-in-container.sh

echo "Build complete: $UPSTREAM_DIR/target/release/codex-plus-plus"
echo "Build complete: $UPSTREAM_DIR/target/release/codex-plus-plus-manager"
