# run-azerothcore

Run an [AzerothCore](https://github.com/azerothcore/azerothcore-wotlk) (WotLK 3.3.5) server in rootless Podman containers that share a single volume — either as three specialized containers or as one all-in-one image.

This repository contains only Containerfiles and scripts. Source, build output, client data and the database all live in the shared volume at [`data/`](data), which is ignored by git.

[Overview](#overview) · [Quick start](#quick-start) · [Commands](#commands) · [Configuration](#configuration) · [Volume layout](#volume-layout) · [Operations](#operations)

## Overview

| Container | Directory | Job |
|-----------|-----------|-----|
| `azeroth-fetch` | [`fetch/`](fetch) | Clones or fast-forwards the AzerothCore source and downloads the client data. |
| `azeroth-build` | [`build/`](build) | Compiles the source with clang/Ninja/ccache and installs it into the volume. |
| `azeroth-server` | [`server/`](server) | Runs MySQL, imports the database schema, then starts `authserver` and `worldserver`. |
| `azeroth-aio` | [`aio/`](aio) | All three stages in one container: fetch, build, then run the server. |

All images mount the same directory at `/vol` and run as your host user, so nothing in the volume is owned by root. Because the source path is identical everywhere (`/vol/src`), the paths compiled into the binaries stay valid at runtime.

## Quick start

**Requirements:** Podman (rootless) and roughly 15 GB of free disk space for source, client data and build output. The first build is long.

```bash
./azeroth images   # build the container images
./azeroth fetch    # source + client data
./azeroth build    # compile and install
./azeroth start    # start MySQL, import the DB, run auth + world servers
```

Or run the whole pipeline in a single container with the all-in-one image:

```bash
./azeroth images && ./azeroth aio
```

`aio` fetches and builds on first run, then starts the server in the foreground; on later runs it skips straight to the server because the binaries are already in the volume. Ctrl-C stops it gracefully, and `FORCE_BUILD=1 ./azeroth aio` redoes the fetch and build. The `azeroth-aio` image is much larger than the three specialized images because it keeps the compiler and MySQL tooling at runtime.

Create an account from the worldserver console:

```bash
./azeroth console
account create <name> <password>
account set gmlevel <name> 3 -1
```

Detach with `Ctrl-P Ctrl-Q`.

> [!WARNING]
> `Ctrl-C` in the console stops the server. Use `Ctrl-P Ctrl-Q` to detach.

Point your 3.3.5a client's `realmlist.wtf` at the host running the server. The auth server listens on port `3724` and the world server on `8085`.

## Commands

Run `./azeroth help` for the full reference.

| Command | Description |
|---------|-------------|
| `images` | Build the container images, including `azeroth-aio`. |
| `fetch` | Clone or update the source; download client data when missing or when the upstream release changes. |
| `build` | Incremental compile and install (4 CPUs / 4 jobs). |
| `start` | Start the server in the background; restarts unless stopped. |
| `stop` | Gracefully stop the server (waits up to 90 s for saves). |
| `logs` | Follow the container output. |
| `console` | Attach to the worldserver console. |
| `update` | `fetch` + `build`, then restart. The server stops only after the build succeeds. |
| `aio` | Run fetch, build and the server in one container (foreground; Ctrl-C stops). |

## Configuration

Set these environment variables when calling `./azeroth`:

| Variable | Used by | Default |
|----------|---------|---------|
| `AZEROTH_VOL` | all | `./data` (inside this folder) |
| `AC_REPO` | `fetch` | AzerothCore on GitHub |
| `AC_BRANCH` | `fetch` | `master` |
| `AC_CLIENT_URL` | `fetch` | latest [wowgaming/client-data](https://github.com/wowgaming/client-data) release |
| `JOBS` | `build` | `4` |
| `CTYPE` | `build` | `RelWithDebInfo` |
| `FORCE_BUILD` | `aio` | unset (set to `1` to redo fetch + build) |

Server settings are in `$AZEROTH_VOL/etc/*.conf`. Defaults are copied there on first start and never overwritten; edit them and run `./azeroth stop && ./azeroth start`.

## Volume layout

| Path | Written by | Contents |
|------|-----------|----------|
| `src/` | fetch | AzerothCore git checkout |
| `client/` | fetch | `dbc`, `maps`, `vmaps`, `mmaps`, `Cameras`, plus the `.source` version stamp |
| `build/`, `ccache/` | build | CMake/Ninja tree and compiler cache (2 GB max) |
| `dist/` | build | Installed binaries and default configs |
| `mysql/` | start | MySQL data directory (all game data) |
| `etc/` | start | `authserver.conf`, `worldserver.conf`, `dbimport.conf`, `acore-db.pw` |
| `logs/` | start | Server, auth and MySQL logs |

## Operations

**Modules:** place them in `$AZEROTH_VOL/src/modules/` and run `./azeroth build`.

**Client data updates:** `fetch` sends a HEAD request to the release URL and compares its size/ETag with `client/.source`; when upstream publishes a new release it re-downloads automatically. Delete `client/.source` to force a fresh download.

**Backups:** stop the server, then copy `mysql/` and `etc/`.

**Remote players:** the realm address defaults to `127.0.0.1`. Update `realmlist.address` in the `acore_auth` database.

> [!NOTE]
> The database password is generated on first start into `etc/acore-db.pw` (mode 600). MySQL listens only inside the container; only ports 3724 and 8085 are published.
