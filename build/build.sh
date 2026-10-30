#!/usr/bin/env bash
# Configures, compiles and installs /vol/src into /vol/dist. Build tree and ccache live in /vol too,
# so rebuilds are incremental.
set -euo pipefail

JOBS=${JOBS:-4}            # hard cap on compiler parallelism; never use $(nproc)
CTYPE=${CTYPE:-RelWithDebInfo}
[[ -f /vol/src/CMakeLists.txt ]] || { echo "[build] no sources in /vol/src; run fetch first" >&2; exit 1; }

export CCACHE_DIR=/vol/ccache CCACHE_MAXSIZE=2G \
       CCACHE_SLOPPINESS=pch_defines,time_macros,include_file_mtime
git config --global --add safe.directory /vol/src

mkdir -p /vol/build && cd /vol/build
cmake /vol/src -G Ninja \
    -DCMAKE_INSTALL_PREFIX=/vol/dist \
    -DAPPS_BUILD=all -DTOOLS_BUILD=db-only \
    -DSCRIPTS=static -DMODULES=static \
    -DCMAKE_BUILD_TYPE="$CTYPE" \
    -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DBoost_USE_STATIC_LIBS=ON
cmake --build . --config "$CTYPE" -j "$JOBS"
cmake --install . --config "$CTYPE"
echo "[build] done"
