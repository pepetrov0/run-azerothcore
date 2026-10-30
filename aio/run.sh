#!/usr/bin/env bash
# All-in-one entrypoint: fetch -> build -> server, in this container.
# fetch/build are skipped once binaries exist, so restarts go straight to the server.
# Set FORCE_BUILD=1 to repeat them.
set -euo pipefail

if [[ -x /vol/dist/bin/worldserver && ${FORCE_BUILD:-0} != 1 ]]; then
    echo "[aio] /vol/dist/bin/worldserver found; skipping fetch+build (FORCE_BUILD=1 to redo)"
else
    echo "[aio] stage 1/3: fetch"
    /bin/bash /fetch.sh
    echo "[aio] stage 2/3: build"
    /bin/bash /build.sh
fi

echo "[aio] stage 3/3: server"
exec /bin/bash /entrypoint.sh
