# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Docker deployments for Apache Jena 6.0.0: CLI tools (`jena/`) and Fuseki SPARQL server with web UI (`fuseki/`). Each subdirectory is self-contained. Versioning is controlled by build args and git tags, not folder names.

## Jena CLI (`jena/`)

Single-stage image based on `eclipse-temurin:21-jre-alpine`. Downloads `apache-jena-6.0.0.tar.gz` from Maven Central, strips javadoc/src/bat, adds bash, puts `/jena/bin` on PATH. WORKDIR is `/rdf` — mount user data there. No fixed ENTRYPOINT; default CMD is `arq --help`.

```bash
# Build
docker build -t jena --build-arg JENA_VERSION=6.0.0 jena/

# Run arq
docker run --rm -v $(pwd):/rdf jena arq --query query.rq --data data.ttl

# Run riot
docker run --rm -v $(pwd):/rdf jena riot --validate data.ttl
```

Logs go to STDERR; query results go to STDOUT — they do not mix.

## Fuseki SPARQL server (`fuseki/`)

All commands are run from the project root.

```bash
# Build
docker compose -f fuseki/docker-compose.yaml build --build-arg JENA_VERSION=6.0.0

# Start
docker compose -f fuseki/docker-compose.yaml up -d

# Stop
docker compose -f fuseki/docker-compose.yaml down
```

Always use `docker compose up`, not `docker compose run --service-ports` — the latter does not publish ports when the service is exclusively on an internal network (Docker bug in v2.29.x, root cause: no docker-proxy spawned).

## How the Fuseki image is built

The Dockerfile has two non-obvious download steps:

1. **`apache-jena-fuseki-6.0.0.tar.gz`** from Maven Central — the server binary distribution. Does NOT include a `webapp/` directory in 6.0.0; that was separated into its own artifact.
2. **`jena-fuseki-ui-6.0.0.jar`** from Maven Central — a pure web asset bundle (compiled Vue.js). The `webapp/` directory is extracted from this JAR into `/fuseki/webapp/` at build time.

The entrypoint delegates to the `fuseki-server` shell script (from the distribution), which selects `FusekiServerUICmd` as the entry point class.

## Web UI flag

`FusekiServerUICmd` looks for static content in this priority order:
1. `--ui <DIR>` CLI flag (what we use)
2. `$FUSEKI_BASE/webapp` (default `./run/webapp` — not where we put it)
3. Classpath resource `webapp` (unreliable)

The `--ui /fuseki/webapp` flag is set in the `command` in `docker-compose.yaml`. If the UI disappears after a config change, this flag is the first thing to check.

## Dataset mode

Controlled by the `command` in `fuseki/docker-compose.yaml`. Two lines are provided; comment/uncomment to switch:

- **In-memory** (`--mem /ds`): default, data lost on stop
- **Persistent TDB2** (`--tdb2 --update --loc databases/DB2 /ds`): requires `fuseki/databases/DB2/` to exist (tracked via `.gitkeep`)

## Networking

Two networks are required:

- **`fuseki-net`** (bridge, non-internal, managed by this compose file): required for host port publishing — Docker blocks port publishing from containers exclusively on internal networks
- **`semantic-web`** (external, internal): service-to-service communication with the broader stack; must be pre-created:
  ```bash
  docker network create --internal semantic-web
  ```

## Authentication

Credentials live only in `fuseki/.env`. The entrypoint generates `/fuseki/run/shiro.ini` at startup from `FUSEKI_ADMIN_USER` / `FUSEKI_ADMIN_PASSWORD` env vars.

Do not use `--passwd`: it creates a separate passwd file but the default shiro.ini still uses `localhostFilter` for `/$/**`, which blocks all admin operations (dataset create/delete, etc.) from outside the container. The generated shiro.ini uses `authcBasic,user[fuseki]` instead, which correctly gates admin access by role.

The healthcheck authenticates via credentials embedded in the wget URL (`http://user:pass@host/path`).

## Key URLs (dataset `/ds`)

| Purpose | URL |
|---------|-----|
| Web UI | `http://localhost:3040/` |
| Liveness | `http://localhost:3040/$/ping` |
| SPARQL Query | `http://localhost:3040/ds/query` |
| SPARQL Update | `http://localhost:3040/ds/update` |
| Graph Store | `http://localhost:3040/ds/data` |

## CI/CD

Each image has its own GitHub Actions workflow (`.github/workflows/jena.yaml` and `.github/workflows/fuseki.yaml`). Builds are triggered independently by path filters on push to `main` and by per-image tag prefixes (`jena/v*`, `fuseki/v*`). Images are published to GHCR.

## Tagging a release

```bash
git tag jena/v6.0.0 && git push origin jena/v6.0.0
git tag fuseki/v6.0.0 && git push origin fuseki/v6.0.0
```

Tags can be pushed independently — only the matching image is built and published.
