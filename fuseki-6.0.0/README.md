# Fuseki 6.0.0

Self-contained Docker deployment of [Apache Jena Fuseki 6.0.0](https://jena.apache.org/documentation/fuseki2/) with the full web UI. Runs as a long-lived SPARQL server.

## Prerequisites

- Docker with Compose v2
- The `semantic-web` external network must exist before starting:

  ```bash
  docker network create --internal semantic-web
  ```

## Configuration

Copy the example env file and edit before first use:

```bash
cp .env.example .env
```

| Variable | Default | Description |
|----------|---------|-------------|
| `FUSEKI_PORT` | `3040` | Host port Fuseki listens on |
| `FUSEKI_ADMIN_USER` | `admin` | Admin username |
| `FUSEKI_ADMIN_PASSWORD` | `password` | Admin password |
| `DOCKER_NETWORK` | `semantic-web` | External Docker network name |

## Build

```bash
docker compose build --build-arg JENA_VERSION=6.0.0
```

## Run

```bash
docker compose up -d      # start
docker compose down       # stop
docker compose logs -f    # follow logs
```

> **Note:** Use `docker compose up`, not `docker compose run --service-ports`. Due to a bug in Compose v2.29.x, the latter does not publish ports when the service is on a non-default network.

## Dataset mode

Controlled by the `command` in `docker-compose.yaml`. Two options are provided — comment/uncomment to switch, then rebuild is not required (restart is enough):

| Mode | Command fragment | Notes |
|------|-----------------|-------|
| In-memory (default) | `--mem /ds` | Data is lost on container stop |
| Persistent TDB2 | `--tdb2 --update --loc databases/DB2 /ds` | Data written to `./databases/DB2/` |

The `databases/DB2/` directory is tracked in git (via `.gitkeep`) so it exists on a fresh checkout. Its contents are gitignored.

## Endpoints

All endpoints require HTTP Basic Auth (`FUSEKI_ADMIN_USER` / `FUSEKI_ADMIN_PASSWORD`), except `/$/ping`.

| Purpose | URL |
|---------|-----|
| Web UI | `http://localhost:3040/` |
| Liveness (no auth) | `http://localhost:3040/$/ping` |
| SPARQL Query | `http://localhost:3040/ds/query` |
| SPARQL Update | `http://localhost:3040/ds/update` |
| Graph Store Protocol | `http://localhost:3040/ds/data` |
| Server status | `http://localhost:3040/$/status` |

## Authentication

Credentials are read from `.env` at container startup. `entrypoint.sh` generates `/fuseki/run/shiro.ini` from `shiro.ini.template` using `envsubst`, substituting only `FUSEKI_ADMIN_USER` and `FUSEKI_ADMIN_PASSWORD`.

The generated `shiro.ini` uses `authcBasic,user[fuseki]` to gate admin endpoints (`/$/**`). This is intentional — do not replace it with Fuseki's `--passwd` flag. The `--passwd` approach creates a separate password file but leaves the default `shiro.ini` in place, which uses `localhostFilter` for `/$/**` and blocks all admin operations (dataset create/delete, UI management) from outside the container.

## Networking

The service is attached to two Docker networks:

| Network | Type | Purpose |
|---------|------|---------|
| `fuseki-net` | Bridge, non-internal (managed here) | Required for host port publishing. Docker does not spawn `docker-proxy` for containers exclusively on internal networks, so port publishing silently fails without this. |
| `semantic-web` | External, internal | Service-to-service communication with the broader stack. The `internal: true` flag prevents outbound internet access from the container. |

## Debugging

To run a one-shot container that probes DNS resolution, ping, and the HTTP endpoints:

```bash
docker compose -f docker-compose.yaml -f docker-compose.debug.yaml up
```

## How the image is built

The Dockerfile has two non-obvious steps that differ from a standard Fuseki deployment:

**1. Server distribution (`apache-jena-fuseki-6.0.0.tar.gz`)**

Downloaded from Maven Central. This tarball does **not** include a `webapp/` directory in 6.0.0 — the web UI was split into a separate artifact in this release.

**2. Web UI assets (`jena-fuseki-ui-6.0.0.jar`)**

Downloaded separately from Maven Central. Despite the `.jar` extension, this is a pure web asset bundle (compiled Vue.js). The `webapp/` directory is extracted from the JAR with `jar xf` and placed at `/fuseki/webapp/`.

The server is started with `--ui /fuseki/webapp` (set in the `command` in `docker-compose.yaml`). `FusekiServerUICmd` resolves static content in this order:

1. `--ui <DIR>` flag ← what we use
2. `$FUSEKI_BASE/webapp` (resolves to `/fuseki/run/webapp` — not where we put it)
3. Classpath resource `webapp` (unreliable)

If the UI returns 404 after a config change, the `--ui` flag is the first thing to check.

The build also uses `jdeps` + `jlink` to produce a minimal JDK in `/opt/java-minimal`, reducing the final image size.
