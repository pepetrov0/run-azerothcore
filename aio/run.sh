#!/usr/bin/env bash
# All-in-one entrypoint: fetch -> build -> server, in this container.
# Once binaries exist, fetch/build are skipped so restarts go straight to the server.
#   FORCE_BUILD=1  always re-run fetch and build
#   AC_PULL=1      fetch on every start and rebuild only if the source commit changed
set -euo pipefail

if [[ -x /vol/dist/bin/worldserver && ${FORCE_BUILD:-0} != 1 ]]; then
    if [[ ${AC_PULL:-0} == 1 ]]; then
        echo "[aio] AC_PULL=1: fetching and checking for source changes"
        if /bin/bash /fetch.sh; then
            built=""
            if [[ -f /vol/dist/.built-from ]]; then
                read -r built < /vol/dist/.built-from || true
            fi
            src=$(git -C /vol/src rev-parse HEAD 2>/dev/null || true)
            if [[ -n $src && $src == "$built" ]]; then
                echo "[aio] source unchanged ($src), not rebuilding"
            else
                echo "[aio] source changed; rebuilding"
                /bin/bash /build.sh
            fi
        else
            echo "[aio] fetch failed; continuing with existing sources and binaries" >&2
        fi
    else
        echo "[aio] /vol/dist/bin/worldserver found; skipping fetch+build (FORCE_BUILD=1 to redo, AC_PULL=1 to check)"
    fi
else
    echo "[aio] stage 1/3: fetch"
    /bin/bash /fetch.sh
    echo "[aio] stage 2/3: build"
    /bin/bash /build.sh
fi

echo "[aio] stage 3/3: server"
exec /bin/bash /entrypoint.sh
