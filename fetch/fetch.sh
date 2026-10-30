#!/usr/bin/env bash
# Downloads sources and client data into the shared volume (/vol). Idempotent.
set -euo pipefail

REPO=${AC_REPO:-https://github.com/azerothcore/azerothcore-wotlk.git}
BRANCH=${AC_BRANCH:-master}
CLIENT_URL=${AC_CLIENT_URL:-https://github.com/wowgaming/client-data/releases/latest/download/Data.zip}
SRC=/vol/src
CLIENT=/vol/client

if [[ -d $SRC/.git ]]; then
    echo "[fetch] updating $SRC ($BRANCH)"
    git -C "$SRC" fetch --depth 1 origin "$BRANCH"
    git -C "$SRC" merge --ff-only FETCH_HEAD   # never clobber local changes
else
    echo "[fetch] cloning $REPO ($BRANCH)"
    git clone --depth 1 --branch "$BRANCH" "$REPO" "$SRC"
fi

if [[ -d $CLIENT/dbc && -d $CLIENT/maps && -d $CLIENT/vmaps && -d $CLIENT/mmaps ]]; then
    echo "[fetch] client data present, skipping"
else
    echo "[fetch] downloading client data (large)"
    mkdir -p "$CLIENT"
    tmp=$(mktemp -d "$CLIENT/.dl.XXXXXX")
    trap 'rm -rf "$tmp"' EXIT
    curl -fL -o "$tmp/Data.zip" "$CLIENT_URL"
    unzip -q -o "$tmp/Data.zip" -d "$CLIENT"
fi
echo "[fetch] done: $(git -C "$SRC" log -1 --format='%h %s')"
