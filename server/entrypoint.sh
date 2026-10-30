#!/usr/bin/env bash
# Supervisor: mysqld + dbimport + authserver + worldserver. Runs as the host user (keep-id); PID 1 is tini.
set -euo pipefail

V=/vol
PWFILE=$V/etc/acore-db.pw
SOCK=/tmp/mysqld.sock
MYSQL_OPTS=(--datadir=$V/mysql --socket=$SOCK --pid-file=/tmp/mysqld.pid
            --bind-address=127.0.0.1 --port=3306 --mysqlx=OFF
            --secure-file-priv=NULL --max_allowed_packet=128M
            --skip-log-bin --innodb-redo-log-capacity=1073741824
            --log-error=$V/logs/mysqld.log)
PIDS=()
log() { echo "[entrypoint] $*"; }

[[ -x $V/dist/bin/worldserver ]] || { log "no binaries in $V/dist; run build first"; exit 1; }
[[ -d $V/client/dbc && -d $V/client/maps ]] || { log "no client data in $V/client; run fetch first"; exit 1; }
mkdir -p $V/mysql $V/etc $V/logs

shutdown() {
    log "stopping..."
    # reverse start order: worldserver saves first, DB last
    for ((i=${#PIDS[@]}-1; i>=0; i--)); do
        kill -TERM "${PIDS[i]}" 2>/dev/null || true
        wait "${PIDS[i]}" 2>/dev/null || true
    done
    exit 0
}
trap shutdown TERM INT

# ---- MySQL ----------------------------------------------------------------
FIRST_RUN=0
if [[ ! -d $V/mysql/mysql ]]; then
    FIRST_RUN=1
    log "initialising MySQL datadir (first run)"
    mysqld "${MYSQL_OPTS[@]}" --initialize-insecure
fi
mysqld "${MYSQL_OPTS[@]}" &
PIDS+=($!)
for _ in $(seq 120); do
    mysqladmin --socket=$SOCK -uroot ping >/dev/null 2>&1 && break
    sleep 1
done
mysqladmin --socket=$SOCK -uroot ping >/dev/null 2>&1 || { log "mysqld failed, see $V/logs/mysqld.log"; exit 1; }

if [[ $FIRST_RUN == 1 || ! -f $PWFILE ]]; then
    log "creating acore user and databases"
    ( umask 077; head -c 18 /dev/urandom | base64 | tr -d '/+=' > "$PWFILE" )
    PW=$(cat "$PWFILE")
    mysql --socket=$SOCK -uroot <<SQL
CREATE USER IF NOT EXISTS 'acore'@'localhost' IDENTIFIED BY '$PW';
CREATE USER IF NOT EXISTS 'acore'@'127.0.0.1' IDENTIFIED BY '$PW';
CREATE DATABASE IF NOT EXISTS acore_auth       DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE DATABASE IF NOT EXISTS acore_characters DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE DATABASE IF NOT EXISTS acore_world      DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL ON acore_auth.*       TO 'acore'@'localhost', 'acore'@'127.0.0.1';
GRANT ALL ON acore_characters.* TO 'acore'@'localhost', 'acore'@'127.0.0.1';
GRANT ALL ON acore_world.*      TO 'acore'@'localhost', 'acore'@'127.0.0.1';
SQL
fi
PW=$(cat "$PWFILE")
export AC_LOGIN_DATABASE_INFO="127.0.0.1;3306;acore;$PW;acore_auth"
export AC_WORLD_DATABASE_INFO="127.0.0.1;3306;acore;$PW;acore_world"
export AC_CHARACTER_DATABASE_INFO="127.0.0.1;3306;acore;$PW;acore_characters"

# ---- configs (never overwrite edits) ---------------------------------------
cp -rn $V/dist/etc/* $V/etc/
for c in authserver worldserver dbimport; do
    [[ -f $V/etc/$c.conf ]] || cp "$V/etc/$c.conf.dist" "$V/etc/$c.conf"
done

# ---- schema ----------------------------------------------------------------
log "running dbimport"
dbimport -c $V/etc/dbimport.conf

# ---- game servers ----------------------------------------------------------
authserver -c $V/etc/authserver.conf &
PIDS+=($!)
# keep stdin attached so the worldserver console works via `azeroth console`
worldserver -c $V/etc/worldserver.conf <&0 &
PIDS+=($!)

log "up: auth :3724, world :8085"
wait -n || true
log "a service exited, shutting down"
shutdown
