#!/usr/bin/env bash
# Downloads sources and client data into the shared volume (/vol). Idempotent.
# The client-data release is versioned with a HEAD request, so a new upstream release is
# detected without downloading the (large) zip unless it actually changed.
set -euo pipefail

REPO=${AC_REPO:-https://github.com/azerothcore/azerothcore-wotlk.git}
BRANCH=${AC_BRANCH:-master}
CLIENT_URL=${AC_CLIENT_URL:-https://github.com/wowgaming/client-data/releases/latest/download/Data.zip}
SRC=/vol/src
CLIENT=/vol/client
STAMP=$CLIENT/.source

# ---- source ----------------------------------------------------------------
if [[ -d $SRC/.git ]]; then
    echo "[fetch] updating $SRC ($BRANCH)"
    git -C "$SRC" fetch --depth 1 origin "$BRANCH"
    git -C "$SRC" merge --ff-only FETCH_HEAD   # never clobber local changes
else
    echo "[fetch] cloning $REPO ($BRANCH)"
    git clone --depth 1 --branch "$BRANCH" "$REPO" "$SRC"
fi

# ---- client data -----------------------------------------------------------
# remote_meta prints the final HEAD response's size and etag, one per line (so an empty
# length can't shift the fields). No output means HEAD is unavailable.
remote_meta() {
    curl -fsSIL --max-time 60 "$CLIENT_URL" 2>/dev/null | tr -d '\r' | awk '
        { line = tolower($0) }
        line ~ /^http\//          { size = ""; etag = "" }
        line ~ /^content-length:/ { size = $2 }
        line ~ /^etag:/           { etag = $2 }
        END { print size; print etag }'
}

# parse_meta VAR "META": sets VAR_size and VAR_etag from remote_meta output, empty when absent.
parse_meta() {
    local prefix=$1 meta=$2
    local -a lines=()
    printf -v "${prefix}_size" '%s' ''
    printf -v "${prefix}_etag" '%s' ''
    if [[ -n $meta ]]; then
        mapfile -t lines <<<"$meta"
        printf -v "${prefix}_size" '%s' "${lines[0]:-}"
        printf -v "${prefix}_etag" '%s' "${lines[1]:-}"
    fi
}

stamp_value() { sed -n "s/^$1=//p" "$STAMP" 2>/dev/null | head -n1; }

write_stamp() {
    printf 'URL=%s\nSIZE=%s\nETAG=%s\n' "$CLIENT_URL" "$1" "$2" > "$STAMP"
}

need=0
remote_size=""
remote_etag=""
if [[ -d $CLIENT/dbc && -d $CLIENT/maps && -d $CLIENT/vmaps && -d $CLIENT/mmaps ]]; then
    parse_meta remote "$(remote_meta || true)"

    if [[ ! -f $STAMP ]]; then
        if [[ -n $remote_size || -n $remote_etag ]]; then
            echo "[fetch] client data present but not versioned; recording current release"
            write_stamp "$remote_size" "$remote_etag"
        else
            echo "[fetch] client data present; remote metadata unavailable, skipping"
        fi
    else
        old_url=$(stamp_value URL)
        old_size=$(stamp_value SIZE)
        old_etag=$(stamp_value ETAG)
        if [[ $old_url != "$CLIENT_URL" ]]; then
            echo "[fetch] client data URL changed; re-downloading"
            need=1
        elif [[ -z $old_size && -z $old_etag ]]; then
            echo "[fetch] client stamp has no version info; recording current release"
            if [[ -n $remote_size || -n $remote_etag ]]; then
                write_stamp "$remote_size" "$remote_etag"
            fi
        elif [[ -n $remote_size && -n $old_size && $remote_size != "$old_size" ]] \
          || [[ -n $remote_etag && -n $old_etag && $remote_etag != "$old_etag" ]]; then
            echo "[fetch] client data changed upstream (size ${old_size:-?} -> ${remote_size:-?}); re-downloading"
            need=1
        else
            echo "[fetch] client data up to date (size ${old_size:-?}); skipping"
        fi
    fi
else
    echo "[fetch] client data missing; downloading"
    need=1
fi

if [[ $need == 1 ]]; then
    echo "[fetch] downloading client data (large)"
    mkdir -p "$CLIENT"
    tmp=$(mktemp -d "$CLIENT/.dl.XXXXXX")
    trap 'rm -rf "$tmp"' EXIT
    got=$(curl -fL -o "$tmp/Data.zip" -w '%{size_download}' "$CLIENT_URL")
    if [[ -n $remote_size && $remote_size != "$got" ]]; then
        echo "[fetch] downloaded $got bytes, expected $remote_size (upstream changed mid-download?)" >&2
        exit 1
    fi
    unzip -q -o "$tmp/Data.zip" -d "$CLIENT"
    after_size=""
    after_etag=""
    parse_meta after "$(remote_meta || true)"
    if [[ -n $after_size && $after_size != "$got" ]]; then
        # The release changed while we were downloading: keep the size only and let the
        # next fetch detect the drift.
        write_stamp "$got" ""
    else
        write_stamp "$got" "$after_etag"
    fi
    echo "[fetch] client data updated (size $got)"
fi

echo "[fetch] done: $(git -C "$SRC" log -1 --format='%h %s')"
